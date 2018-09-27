using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace AdminHelper.Misc
{
    public class Matrix
    {
        public string[,] Rotate90Right(string [,] mas, int iMax, int jMax)
        {
            string[,] rot = new string[jMax, iMax];

            //Matrix demension minus 1
            //int iMax = 7;
            //int jMax = 4;

            /*//Matrixes
            string[,] mas = new string[iMax, jMax];

            //A matrix row
            string row = "";

            //Source matrix		
            for (int i = 0; i <= iMax - 1; i++)
            {
                for (int j = 0; j <= jMax - 1; j++)
                {
                    mas[i, j] = "(" + i + "," + j + ")";
                    row = row + mas[i, j];
                }
                Console.WriteLine(row);
                row = "";
            }

            //Space between matrix
            Console.WriteLine();*/

            //Rotate matrix on 90 degrees right
            for (int j = 0; j <= jMax - 1; j++)
            {
                for (int i = 0; i <= iMax - 1; i++)
                {
                    rot[j, i] = mas[iMax - i - 1, j];
                    //row = row + rot[j, i];
                }
                //Console.WriteLine(row);
                //row = "";
            }

            return rot;
        }
    }
}
