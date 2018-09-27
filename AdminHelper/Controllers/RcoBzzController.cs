using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Data.SqlClient;
using System.Configuration;
using System.Collections;
using System.Data;


namespace AdminHelper.Controllers
{
    public class RcoBzzController : Controller
    {
        //Create direct connection to database
        static string db = ConfigurationManager.ConnectionStrings["main"].ConnectionString;
        static SqlConnection cn = new SqlConnection(db);

        //GET: Rco
        public ActionResult Index()
        {
            //---- Begin ---- Query database for consumers statuses ----
                //Start and end dates
                string endDate = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                string startDate = DateTime.Now.AddDays(-1).ToString("yyyy-MM-dd HH:mm:ss");

                //Database query
                SqlCommand cmd = new SqlCommand("SELECT * FROM HealthyRcoBzz WHERE date > '" + startDate + "' and date < '" + endDate + "' order by id desc", cn);
                SqlDataAdapter da = new SqlDataAdapter(cmd);
                DataTable dt = new DataTable();
                da.Fill(dt);
                ViewBag.Rows = dt.Rows;
            //---- End ---- Query database for consumers statuses ----

            //---- Begin ---- Query database for services statuses ----
                //Database query
                SqlCommand cmd1 = new SqlCommand("select top 100 * from HealthyRcoStatus order by id desc", cn);
                SqlDataAdapter da1 = new SqlDataAdapter(cmd1);
                DataTable dt1 = new DataTable();
                da1.Fill(dt1);
                ViewBag.Rows1 = dt1.Rows;
            //---- End ---- Query database for services statuses ----


            //---- Begin ---- Create servers list ----
            List<Server> servers = new List<Server>();

            servers.Add(new Server() { Name = "ab-ner01", ConsumersNumber = 12 });
            servers.Add(new Server() { Name = "ab-v-nerrco01", ConsumersNumber = 2 });
            servers.Add(new Server() { Name = "ab-v-nerrco02", ConsumersNumber = 2 });
            servers.Add(new Server() { Name = "ab-v-nerrco03", ConsumersNumber = 2 });
            servers.Add(new Server() { Name = "ab-v-nerrco04", ConsumersNumber = 2 });
            servers.Add(new Server() { Name = "ab-v-nerrco05", ConsumersNumber = 2 });
            servers.Add(new Server() { Name = "ab-v-nerrco06", ConsumersNumber = 2 });
            servers.Add(new Server() { Name = "ab-v-nerrco07", ConsumersNumber = 3 });
            servers.Add(new Server() { Name = "ab-v-nerrco08", ConsumersNumber = 3 });
            servers.Add(new Server() { Name = "ab-v-nerrco09", ConsumersNumber = 3 });
            servers.Add(new Server() { Name = "ab-v-nerrco10", ConsumersNumber = 3 });
            servers.Add(new Server() { Name = "ab-v-nerrco11", ConsumersNumber = 3 });
            servers.Add(new Server() { Name = "ab-v-nerrco12", ConsumersNumber = 3 });
            servers.Add(new Server() { Name = "ab-v-nerrco13", ConsumersNumber = 3 });
            servers.Add(new Server() { Name = "ab-v-nerrco14", ConsumersNumber = 3 });
            servers.Add(new Server() { Name = "ab-v-nerrco15", ConsumersNumber = 3 });
            servers.Add(new Server() { Name = "ab-v-nerrco16", ConsumersNumber = 3 });
            servers.Add(new Server() { Name = "ab-v-nerrco17", ConsumersNumber = 3 });
            servers.Add(new Server() { Name = "ab-v-nerrco18", ConsumersNumber = 3 });
            servers.Add(new Server() { Name = "ab-v-nerrco19", ConsumersNumber = 3 });
            servers.Add(new Server() { Name = "ab-v-nerrco20", ConsumersNumber = 3 });
            servers.Add(new Server() { Name = "ab-v-nerrco21", ConsumersNumber = 3 });
            servers.Add(new Server() { Name = "ab-v-nerrco22", ConsumersNumber = 3 });
            servers.Add(new Server() { Name = "ab-v-nerrco23", ConsumersNumber = 3 });
            servers.Add(new Server() { Name = "ab-v-nerrco24", ConsumersNumber = 3 });
            servers.Add(new Server() { Name = "ab-v-nerrco25", ConsumersNumber = 4 });

            ViewBag.Servers = servers;
            //---- End ---- Create servers list ----

            return View();
        }
    }
    public class Server
    {
        public string Name { get; set; }
        public int ConsumersNumber { get; set; }
    }

}