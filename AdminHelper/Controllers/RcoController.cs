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
    public class RcoController : Controller
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
                SqlCommand cmd = new SqlCommand("SELECT * FROM HealthyRco WHERE date > '" + startDate + "' and date < '" + endDate + "' order by id desc", cn);
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

            return View();
        }
    }
}