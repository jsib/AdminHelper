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
using System.Net.Sockets;
using System.Management;

namespace HealthyRcoBzz
{
    class Program
    {
        //Create direct connection to database
        static string db = ConfigurationManager.ConnectionStrings["main"].ConnectionString;
        static SqlConnection cn = new SqlConnection(db);

        static int Main(string[] args)
        {

            //- Begin --------------------- Get consumers from rabbitmq -----------------------------
                //Create cookie container
                CookieContainer myContainer = new CookieContainer();

                //Create http request
                HttpWebRequest request = (HttpWebRequest)WebRequest.Create("http://ab-v-nerq01:15672/api/consumers");

                //Create request
                request.Credentials = new NetworkCredential("test", "test");
                request.CookieContainer = myContainer;
                request.PreAuthenticate = true;
                
                //Encode login and password
                String encoded = System.Convert.ToBase64String(System.Text.Encoding.GetEncoding("ISO-8859-1").GetBytes("test" + ":" + "test"));

                //Add security header to request
                request.Headers.Add("Authorization", "Basic " + encoded);

                //Create response object
                HttpWebResponse response = (HttpWebResponse)request.GetResponse();

                //Read response data to string
                string strResponse = "";
                using (var sr = new StreamReader(response.GetResponseStream()))
                {
                    strResponse = sr.ReadToEnd();
                }

                //Transform text to json object
                dynamic deserializedJson = JsonConvert.DeserializeObject(strResponse);
            //- End --------------------- Get consumers from rabbitmq -----------------------------

            //This string will contain server name and port of active consumer
            string rco_string = "";

            //Loop over consumers and retrive some data
            foreach (JObject jsonObject in deserializedJson)
            {
                if (Convert.ToString(jsonObject["queue"]["name"]) == "RcoKernel")
                {
                    //Fetch ip address
                    string ip_address = Convert.ToString(jsonObject["channel_details"]["peer_host"]);

                    //Get MO object
                    ManagementObjectSearcher theSearcher = new ManagementObjectSearcher("\\\\" + ip_address + "\\root\\CIMv2", "SELECT Name FROM Win32_ComputerSystem");
                    var queryCollection = from ManagementObject x in theSearcher.Get() select x;
                    var moobj = queryCollection.First();

                    //Get computer name and peer port
                    string hostname = moobj["Name"].ToString();
                    string peer_port = jsonObject["channel_details"]["peer_port"].ToString();
                    string consumer_tag = Convert.ToString(jsonObject["consumer_tag"]);

                    //Write collected data to string
                    rco_string += hostname + ":" + peer_port + ":" + consumer_tag + ";";
                }
            }

            //Write data to database if some data presented
            if (rco_string != "")
            {
                //Remove last semicolon from result string
                rco_string = rco_string.Remove(rco_string.Length - 1, 1);

                //Insert to database
                cn.Open();
                SqlCommand cmd = new SqlCommand("INSERT INTO HealthyRcoBzz (date, rco) values(CURRENT_TIMESTAMP, '" + rco_string + "')", cn);
                cmd.ExecuteNonQuery();
            }


            //Write console
            Console.WriteLine(rco_string);

            //Console.WriteLine(cons.Email);*/
            //Console.WriteLine("Press enter to close...");
            //Console.ReadLine();

            return 1;
        }
    }
}
