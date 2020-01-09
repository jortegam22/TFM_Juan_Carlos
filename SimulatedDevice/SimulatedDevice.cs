using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Azure.Devices.Client;
using Newtonsoft.Json;

namespace SimulatedDevice
{
    class Program
    {
        static DeviceClient deviceClient;
        static string iotHubUri = "HostName=eventiothub.azure-devices.net;DeviceId=Device2;SharedAccessKey=f890dFNnD5yxSvS/elFyJ1q805zdC+VtPqbrJ7B4FjU=";
        //static string deviceKey = "f890dFNnD5yxSvS/elFyJ1q805zdC+VtPqbrJ7B4FjU=";
        static string deviceID = "Device2";
        static void Main(string[] args)
        {
            Console.WriteLine("Simulated device\n");
            deviceClient = DeviceClient.CreateFromConnectionString(iotHubUri);//, new DeviceAuthenticationWithRegistrySymmetricKey(deviceID, deviceKey), TransportType.Mqtt);
            deviceClient.ProductInfo = "HappyPath_Simulated-CSharp";
            SendDeviceToCloudMessagesAsync();
            Console.ReadLine();
        }

        private static async void SendDeviceToCloudMessagesAsync()
        {
            int startFloor = 0;
            int endFloor = 0;
            int error = 0;
            string description;
            bool env = true; //1 if the device is Production and 0 if it is for stable
            int var = 0;
            int messageId = 0;
            Random rand = new Random();

            int count = 0;

            while (true)
            {
                count++;

                double Evento = rand.NextDouble();

                DateTime thisDay = DateTime.Now;

                if (Evento <= 0.8)
                {
                    endFloor = endFloor + rand.Next(1, 12);
                    
                    if (endFloor == var) { endFloor++;}

                    if (count <= 1) {startFloor = 0;} else {startFloor = var;}

                    var = endFloor;

                    var telemetryDataPoint = new
                    {
                        messageId = messageId++,
                        deviceId = deviceID,
                        eventType = "Trip",
                        startFloor = startFloor,
                        endFloor = endFloor,
                        environment = env,
                        date = thisDay
                    };

                    endFloor = 0;

                    var messageString = JsonConvert.SerializeObject(telemetryDataPoint);
                    var message = new Message(Encoding.ASCII.GetBytes(messageString));

                    await deviceClient.SendEventAsync(message);
                    Console.WriteLine("{0} > Sending message: {1}", DateTime.Now, messageString);
                }
                else
                {
                    error = error + rand.Next(0, 10);

                    if (error <= 2)
                    {
                        description = "Fallo en las puertas";
                    }
                    else
                    {
                        if (error >= 7)
                        {
                            description = "Fallo por sobrecarga";
                        }
                        else
                        {
                            description = "Fallo en los pulsadores";
                        }
                    }

                    var telemetryDataPoint = new
                    {
                        messageId = messageId++,
                        deviceId = deviceID,
                        eventType = "Error",
                        error = error,
                        description = description,
                        environment = env,
                        date = thisDay
                    };

                    var messageString = JsonConvert.SerializeObject(telemetryDataPoint);
                    var message = new Message(Encoding.ASCII.GetBytes(messageString));

                    await deviceClient.SendEventAsync(message);
                    Console.WriteLine("{0} > Sending message: {1}", DateTime.Now, messageString);

                    error = 0;
                Evento = 0;
                }               

                await Task.Delay(15000);
            }
        }
    }
}
