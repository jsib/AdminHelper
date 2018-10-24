using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Net;
using System.Text.RegularExpressions;
using System.Data.SqlClient;
using System.Configuration;
using System.Collections;

namespace HealthyRco
{
    class Program
    {
        //Create direct connection to database
        static string db = ConfigurationManager.ConnectionStrings["main"].ConnectionString;
        static SqlConnection cn = new SqlConnection(db);

        static int Main(string[] args)
        {

            //Get consumers from rabbitmq
            CookieContainer myContainer = new CookieContainer();
            HttpWebRequest request = (HttpWebRequest)WebRequest.Create("http://smi-v-nerq01.mlg.ru:15672/api/consumers");
            request.Credentials = new NetworkCredential("test", "test");
            request.CookieContainer = myContainer;
            request.PreAuthenticate = true;
            String encoded = System.Convert.ToBase64String(System.Text.Encoding.GetEncoding("ISO-8859-1").GetBytes("test" + ":" + "test"));
            request.Headers.Add("Authorization", "Basic " + encoded);
            HttpWebResponse response = (HttpWebResponse)request.GetResponse();
            string strResponse = "";
            using (var sr = new StreamReader(response.GetResponseStream()))
            {
                strResponse = sr.ReadToEnd();

            }

            dynamic deserializedJson = JsonConvert.DeserializeObject(strResponse);

            string pattern = @"([0-9]{1,3})";
            Regex rgx = new Regex(pattern, RegexOptions.IgnoreCase);
            int[] rcos = new int[100];

            foreach (JObject jsonObject in deserializedJson) {
                if (Convert.ToString(jsonObject["queue"]["name"]) == "RcoKernel") {
                    IPHostEntry IpToDomainName = Dns.GetHostEntry(Convert.ToString(jsonObject["channel_details"]["peer_host"]));
                    string hostname = IpToDomainName.HostName.Trim();
                    MatchCollection matches = rgx.Matches(hostname);
                    int rcoNum = Convert.ToInt32(matches[0].Value);
                    rcos[rcoNum] = 1;
                }
            }

            //Number of rco
            int rco_number = 25;
            string rco_string = "";

            //Get which RCO consumers not read now
            for (int i = 1; i <= rco_number; i++) {
                if (rcos[i] == 1) {
                    rco_string += i + ";"; 
                }
            }

            //Remove last semicolon
            rco_string = rco_string.Remove(rco_string.Length - 1, 1);

            //Insert to database
            cn.Open();
            SqlCommand cmd = new SqlCommand("INSERT INTO HealthyRco (date, rco) values(CURRENT_TIMESTAMP, '" + rco_string + "')", cn);
            cmd.ExecuteNonQuery();

            //Write console
            //Console.WriteLine(rco_string);

            //Console.WriteLine(cons.Email);
            //Console.WriteLine("Press enter to close...");
            //Console.ReadLine();

            return 1;
        }
    }
}
