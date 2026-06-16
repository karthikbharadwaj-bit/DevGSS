global with sharing class SpringCMHTTPRequestor {
    private SpringCMIAuthenticator auth;
   
    private static Integer RunningRequests;
  
    global integer AutomaticRetrys { get; set; }
 
    global SpringCMHTTPRequestor(SpringCMIAuthenticator authenticator)
    {
        this.auth = authenticator;
        this.AutomaticRetrys = 10;
    }
    public string Post(string url, string body, map<string, string> headers)
    {
        string json =  MakeCall(url, body, headers, 'POST', null);
        return json;
    }
    // public async Task<T> Post<T>(string url, string body, Map<string, string> headers = null)
    // {
    //     if (headers == null)
    //     {
    //         headers = new Map<string, string>();
    //     }
    //     var json = await MakeCall(url, body, headers, "POST");
    //     return JsonConvert.DeserializeObject<T>(json, JSONService.Settings);
    // }

    // public async Task<string> Post(string url, Map<string, string> headers = null)
    // {
    //     if (headers == null)
    //     {
    //         headers = new Map<string, string>();
    //     }
    //     var json = await MakeCall(url, headers, "POST");
    //     return json;
    // }
    global string Get(string url, Map<string, string> headers )
    {
        system.debug(url);
        if (headers == null)
        {
            headers = new Map<string, string>();
        }
        string json =  MakeCall(url, null, headers, 'GET',0);
        system.debug(json);
        return json;
    }
    // public async Task<T> Get<T>(string url, Map<string, string> headers = null)
    // {
    //     if (headers == null)
    //     {
    //         headers = new Map<string, string>();
    //     }
    //     var json = await MakeCall(url, null, headers, "GET");
    //     return JsonConvert.DeserializeObject<T>(json, JSONService.Settings);
    // }

    global string DeleteCall(string url, Map<string, string> headers )
    {
        if (headers == null)
        {
            headers = new Map<string, string>();
        }
        system.debug(url);
        string json =  MakeCall(url, null, headers, 'DELETE',0);
        return json;
    }
    global string Put(string url,string body, Map<string, string> headers )
    {
        if (headers == null)
        {
            headers = new Map<string, string>();
        }
        string json =  MakeCall(url, body, headers, 'PUT',0);
        return json;
    }

    // public async Task<string> Delete(string url, Map<string, string> headers = null)
    // {
    //     if (headers == null)
    //     {
    //         headers = new Map<string, string>();
    //     }
    //     var json = await MakeCall(url, null, headers, "DELETE");
    //     return json;
    // }
    // public async Task<T> Patch<T>(string url, string body, Map<string, string> headers = null)
    // {
    //     if (headers == null)
    //     {
    //         headers = new Map<string, string>();
    //     }
    //     var json = await MakeCall(url, body, headers, "PATCH");
    //     return JsonConvert.DeserializeObject<T>(json, JSONService.Settings);
    // }

    // public async Task<T> PostFile<T>(string url, Stream file, string fileName, Map<string, string> headers = null,int retrycount =0 )
    // {
    //     if (headers == null)
    //     {
    //         headers = new Map<string, string>();
    //     }

    //     HttpClient httpClient = new HttpClient();
    //     if (_auth != null)
    //     {
    //         httpClient.DefaultRequestHeaders.Add("Authorization", $"bearer {_auth.AccessToken}");
    //     }
    //     MultipartFormDataContent form = new MultipartFormDataContent();

    //     httpClient.Timeout = new TimeSpan(0, 30, 0);

    //     form.Add(new StreamContent(file), fileName, fileName);
    //     bool canRun = false;
    //     lock (lck)
    //     {
    //         canRun = RunningRequests < MAXREQUESTS;
    //         if (canRun)
    //         {
    //             RunningRequests++;
    //         }
    //     }
    //     while (!canRun)
    //     {

    //         Console.WriteLine($"Waiting to send request there are {RunningRequests} running requests.");
    //         await Task.Delay(500);
              
    //         lock (lck)
    //         {
    //             canRun = RunningRequests < MAXREQUESTS;
    //             if (canRun)
    //             {
    //                 RunningRequests++;
    //             }
    //         }
    //     }
    //     HttpResponseMessage response;
    //     try
    //     {
    //          response = await httpClient.PostAsync(url, form);
    //     }
    //     catch (HttpRequestException ex)
    //     {
    //         if (retrycount < AutomaticRetrys)
    //         {
    //             return await PostFile<T>(url, file, fileName, null, retrycount + 1);
    //         }
    //         throw ex;
    //        // response = await httpClient.PostAsync(url, form);
    //     }
    //     //HttpResponseMessage response = await httpClient.PostAsync(url, form);

    //     response.EnsureSuccessStatusCode();
    //     httpClient.Dispose();
    //     string sd = await response.Content.ReadAsStringAsync();
    //     lock (lck)
    //     {
            
    //         RunningRequests--;
    //     }
    //     return JsonConvert.DeserializeObject<T>(sd, JSONService.Settings);
    // }

    // public async Task<T> Put<T>(string url, string body, Map<string, string> headers = null)
    // {
    //     if (headers == null)
    //     {
    //         headers = new Map<string, string>();
    //     }
    //     var json = await MakeCall(url, body, headers, "PUT");
    //     return JsonConvert.DeserializeObject<T>(json, JSONService.Settings);
    // }
    
    
    global String PostBlob (string url, Blob body, Map<string, string> headers, Integer numberofTrys){
        
        if (numberofTrys == null){
            numberofTrys = 0;
        }
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(url);
            req.setMethod('POST');
            req.setBodyAsBlob(body);

            System.debug(url);
            
            //adds all the passed in headers

            //req.setHeader('Content-Type', 'application/json');
            
            if (auth != null)
            {
                
               system.debug('auth has value');
                req.setHeader('Authorization', 'bearer ' + auth.AccessToken());
            }
            for(string key : headers.keySet()){
                req.setHeader(key, headers.get(key));
            }

            req.setTimeout(30000);

            //System.debug(req);
           
            HttpResponse res ;   
            
            try { 
                 res = h.send(req);
            }
            catch (Exception ex)
            {
                if (numberofTrys < AutomaticRetrys)
                {
                    return  PostBlob(url, body, headers, numberofTrys + 1);
                }
                throw ex;
            }

            //System.debug(res);
           
            if (res.getStatusCode() > 300)
            {
                // ApiError ae = JsonConvert.DeserializeObject<ApiError>(res, JSONService.Settings);
                // if (ae.Error.HttpStatusCode == 429 && numberofTrys < AutomaticRetrys)
                // {
                //     Thread.Sleep(2000);
                //     var newTry = numberofTrys + 1;
                //     return await MakeCall(url, body, headers, method, newTry);
                // }
                System.debug(req.getBody());
                System.debug(res.getBody());
                CalloutException e = new CalloutException();
                e.setMessage('there was an error making a call to the api');
                throw e;
            }
            
            string bod = res.getBody();
            //System.debug(req.getEndpoint());
            //system.debug(bod);
            return bod;

    }
    
    global Blob GetBlob (string url, Map<string, string> headers, Integer numberofTrys){
        
        if (numberofTrys == null){
            numberofTrys = 0;
        }
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(url);
            req.setMethod('GET');

            //System.debug(url);
            
            //adds all the passed in headers

            req.setHeader('Content-Type', 'application/json');
            
            if (auth != null)
            {
                
               system.debug('auth has value');
                req.setHeader('Authorization', 'bearer ' + auth.AccessToken());
            }
            for(string key : headers.keySet()){
                req.setHeader(key, headers.get(key));
            }

            req.setTimeout(30000);

            //System.debug(req);
           
            HttpResponse res ;   
            
            try { 
                 res = h.send(req);
            }
            catch (Exception ex)
            {
                if (numberofTrys < AutomaticRetrys)
                {
                    return  GetBlob(url, headers, numberofTrys + 1);
                }
                throw ex;
            }

            //System.debug(res);
           
            if (res.getStatusCode() > 300)
            {
                // ApiError ae = JsonConvert.DeserializeObject<ApiError>(res, JSONService.Settings);
                // if (ae.Error.HttpStatusCode == 429 && numberofTrys < AutomaticRetrys)
                // {
                //     Thread.Sleep(2000);
                //     var newTry = numberofTrys + 1;
                //     return await MakeCall(url, body, headers, method, newTry);
                // }
                System.debug(req.getBody());
                System.debug(res.getBodyAsBlob());
                CalloutException e = new CalloutException();
                e.setMessage('there was an error making a call to the api');
                throw e;
            }
            
            blob bod = res.getBodyAsBlob();
            //System.debug(req.getEndpoint());
            //system.debug(bod);
            return bod;

    }



    // public async Task<Stream> GetStream(string url, int numberofTrys = 0)
    // {
    //     using (var httpClient = new HttpClient())
    //     {
    //         //httpClient.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36");
    //         if (_auth != null)
    //         {
    //             httpClient.DefaultRequestHeaders.Add("Authorization", $"bearer {_auth.AccessToken}");
    //         }

    //         var request = new HttpRequestMessage(new HttpMethod("GET"), url);

    //         httpClient.Timeout = new TimeSpan(0, 0, 30, 0);
    //         HttpResponseMessage response = new HttpResponseMessage();

    //         response = await httpClient.SendAsync(request);


    //         var res = await response.Content.ReadAsStreamAsync();
    //         if (!response.IsSuccessStatusCode)
    //         {
    //             ApiError ae = JsonConvert.DeserializeObject<ApiError>(response.Content.ReadAsStringAsync().Result, JSONService.Settings);
    //             if (ae.Error.HttpStatusCode == 429 && numberofTrys < AutomaticRetrys)
    //             {
    //                 Thread.Sleep(2000);
    //                 var newTry = numberofTrys + 1;
    //                 return await GetStream(url, newTry);

    //             }
    //             throw new ApiException(ae.Error.DeveloperMessage) { ApiError = ae };
    //         }
    //         return res;
    //     }
    // }

    // //public async Task<string> MakeCallAsync(string url, string body, Map<string, string> headers, string method, int numberofTrys = 0)
    // //{
    // //    var task = Task<String>.Run(() => MakeCall(url,body,headers,method,numberofTrys));
    // //    return await task;
    // //}

    public string MakeCall(string url, string body, Map<string, string> headers, string method, Integer numberofTrys)
    {
        if (numberofTrys == null){
            numberofTrys = 0;
        }
            Http h = new Http();
                HttpRequest req = new HttpRequest();
                req.setEndpoint(url);
                req.setMethod(method);
                if (body != null){
                    req.setBody(body);
                }
                //adds all the passed in headers
                
               
               
            req.setHeader('Content-Type', 'application/json');
            
            if (auth != null)
            {
                
               system.debug('auth has value');
                req.setHeader('Authorization', 'bearer ' + auth.AccessToken());
            }
            for(string key : headers.keySet()){
                req.setHeader(key, headers.get(key));
            }
           
           
            req.setTimeout(30000);
           
            HttpResponse res ;   
            
            try { 
                 res = h.send(req);
            }
            catch (Exception ex)
            {
                if (numberofTrys < AutomaticRetrys)
                {
                    return  MakeCall(url, body ,headers, method, numberofTrys + 1);
                }
                throw ex;
            }
           
            if (res.getStatusCode() > 300)
            {
                // ApiError ae = JsonConvert.DeserializeObject<ApiError>(res, JSONService.Settings);
                // if (ae.Error.HttpStatusCode == 429 && numberofTrys < AutomaticRetrys)
                // {
                //     Thread.Sleep(2000);
                //     var newTry = numberofTrys + 1;
                //     return await MakeCall(url, body, headers, method, newTry);
                // }
                System.debug(req.getBody());
                //System.debug(res.getBody());
                CalloutException e = new CalloutException();
                e.setMessage('there was an error making a call to the api');
                throw e;
            }
            System.debug(req.getBody());
            string bod = res.getBody();
            System.debug(req.getEndpoint());
            //system.debug(bod);
            return bod;
            //return res;
        }


    // }

    // public async Task<string> MakeCall(string url, Map<string, string> headers, string method, int numberofTrys = 0)
    // {
    //     using (var httpClient = new HttpClient())
    //     {
    //         //httpClient.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36");
    //         httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
    //         if (_auth != null)
    //         {
    //             httpClient.DefaultRequestHeaders.Add("Authorization", $"bearer {_auth.AccessToken}");
    //         }
    //         foreach (var header in headers)
    //         {
    //             httpClient.DefaultRequestHeaders.Add(header.Key, header.Value);
    //         }
    //         var request = new HttpRequestMessage(new HttpMethod(method), url);

    //         httpClient.Timeout = new TimeSpan(0, 0, 30, 0);
    //         HttpResponseMessage response = new HttpResponseMessage();
    //         bool canRun = false;
    //         lock (lck)
    //         {
    //             canRun = RunningRequests < MAXREQUESTS;
    //             if (canRun)
    //             {
    //                 RunningRequests++;
    //             }
    //         }
    //         while (!canRun)
    //         {

    //             Console.WriteLine($"Waiting to send request there are {RunningRequests} running requests.");
    //             await Task.Delay(500);
    //             lock (lck)
    //             {
    //                 canRun = RunningRequests < MAXREQUESTS;
    //                 if (canRun)
    //                 {
    //                     RunningRequests++;
    //                 }
    //             }
    //         }
    //         string res;
    //         try
    //         {
    //             response = await httpClient.SendAsync(request);
    //             res = await response.Content.ReadAsStringAsync();
    //         }
    //         catch (Exception ex)
    //         {
    //             if (numberofTrys < AutomaticRetrys)
    //             {
    //              return await   MakeCall(url, headers, method, numberofTrys + 1);
    //             }
    //             throw ex;
    //         }
           
    //         lock (lck)
    //         {

    //             RunningRequests--;
    //         }
    //         if (!response.IsSuccessStatusCode)
    //         {
    //             ApiError ae = JsonConvert.DeserializeObject<ApiError>(res, JSONService.Settings);
    //             if (ae.Error.HttpStatusCode == 429 && numberofTrys < AutomaticRetrys)
    //             {
    //                await Task.Delay(2000);
    //                 var newTry = numberofTrys + 1;
    //                 return await MakeCall(url, headers, method, newTry);
    //             }
    //             throw new ApiException(ae.Error.DeveloperMessage) { ApiError = ae };
    //         }
    //         return res;
    //     }


 //   }

}