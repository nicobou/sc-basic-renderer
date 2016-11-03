// Satie4Unity, audio rendering support for Unity
// Copyright (C) 2016  Zack Settel

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
// -----------------------------------------------------------
using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Threading;
using System.Runtime.InteropServices;
using System.Net;
using OSC.NET;
using UnityEngine.UI;

// this script must be attached to a game object called "spatOSCroot"

public class SATIEsetup : MonoBehaviour {

    //public bool enabled = true;
   
    private bool connected = false;
       
    public bool isConnected() { return connected; }
 
    private static OSCTransmitter sender;

    public string RendererAddress = "localhost";
	public int RendererPort = 18032;

 
    public int getPort() {
    return RendererPort;
    }

    public string getAddress() {
        return RendererAddress;
    }
   
	public bool useFixedUpdate = false;

    public float updateRateMs = 30;
    private float _updateRateMs;

	public bool invertAzimuth = false;

	public static bool invertAzi = false;   // this is referenced by source connections


    public static bool debugMessTx_static = false;
    public bool debugMessTx = false;


	[HideInInspector] 
    public static float updateRateSecs = .02f;


      
    // list of all instantiated nodes
    [HideInInspector] 
    public  static List<SATIEnode> SATIEnodeList = new List<SATIEnode>();
  
//    public Vector3 SceneOrientation = new Vector3(90f,180f,180f);
//    private Vector3 _sceneOrientation = new Vector3(0f,0f,0f);
//
//    public bool invertX = false;
//    private static float _invertX;
//
//    public bool invertY = false;
//    private static float _invertY;
//
//    public bool invertZ = false;
//    private static float _invertZ;
//
//    public static bool swapYandZ = false;


   // public Vector3 SceneTranslation = new Vector3(0f,0f,0f);

	private bool _enabled = false;

    public static bool OSCenabled { get { return _instance._enabled; } }

    //private static readonly SATIEsetup _instance = new SATIEsetup();

    private static  SATIEsetup _instance = null;
 
    public static SATIEsetup Instance { get { return _instance; } }
	
    public SATIEsetup() {}



	Text fpsText = null;  // used to display FPS


	private int frameCount = 0;
	private float dt = 0.0f;
	private float fps = 0.0f;
	private float updateRate = 4.0f;  // 4 updates per sec.

 
    // set up translator(s)  for now, using only the basic translator
	void Awake () 
	{
        if (_instance != null) 
        {
            Debug.LogError("SATIEsetup.Awake: multiple instances of SATIEsetup not allowed, duplicate instance found in:" + transform.name);
            return;
        }
	

        try
        {
             sender = new OSCTransmitter(RendererAddress, RendererPort);
            //thread = new Thread(new ThreadStart(listen));
            //thread.Start();
        } catch (Exception e)
        {
            Debug.LogError("SATIEsetup.Awake: OSC TX:  failed to connect to " + RendererAddress + ":" + RendererPort + "can't initialize SATIE");
            Debug.LogWarning(e.Message);
            return;

        }
        // connected and ready to initialize object

        connected = true;
        _instance = this;    // force singleton
        _instance._enabled = true;

        string localHostName = Dns.GetHostName();
        IPHostEntry hostEntry = Dns.GetHostEntry(localHostName);
        foreach (IPAddress ipAddr in hostEntry.AddressList)
        {
            Debug.Log("SATIEsetup.Awake: MY IP:" + ipAddr.ToString());
        }
        Debug.Log("SATIEsetup.Awake: OSC TX to:  " + RendererAddress + ":" + RendererPort);

        setUpdateRate(updateRateMs);
	}



	
	void Start()
	{
		GameObject obj = GameObject.Find("FPStext");

		if (obj != null) fpsText = obj.GetComponent<Text> ();

		invertAzi = invertAzimuth;

        debugMessTx_static = debugMessTx;


		StartCoroutine( initSatie() );
	}
	
	
    void OnValidate()
    {
        if (!connected) return;

        if (_updateRateMs != updateRateMs )        
            setUpdateRate( updateRateMs );

		if (invertAzi != invertAzimuth)
				invertAzi = invertAzimuth;

        if (debugMessTx_static != debugMessTx)
            debugMessTx_static = debugMessTx;
    }


    void setUpdateRate(float updateMs)
    {
        _updateRateMs = updateMs;
        updateRateSecs = updateMs / 1000f;
    }


    IEnumerator initSatie() // now that litener(s) have been conection related parameters.
    {
        yield return new WaitForSeconds(.1f);   // may need to be bigger for large scenes
        refreshNodes();    // or do this using a coroutine to avoid OSC peaking
    }

    public void refreshNodes()
    {
        foreach (SATIEnode  node in SATIEnodeList)
            node.refreshState();
    }

	// connections are serviced after the previous frame's physics engine is updated during lateUpdate() 
	public virtual void FixedUpdate () 
	{
		if (useFixedUpdate)
			serviceConnections(); 
	}
	
	// Update is called once per frame
	public virtual void Update () 
	{
		frameCount++;
		dt += Time.deltaTime;
		if (dt > 1.0f/updateRate)
		{
			fps = frameCount / dt ;
			frameCount = 0;
			dt -= 1.0f/updateRate;
		}
		if (fpsText)
			fpsText.text = ((int)fps).ToString() + " fps, frameDurMS: "+ ((int) (Time.deltaTime * 1000f)).ToString();
		if (!useFixedUpdate)
			serviceConnections();    
	} 
	
    private float _lastUpdate;

    void serviceConnections()
    {
		if (!connected) return;

		if (Time.time - _lastUpdate > updateRateSecs)
        {
			// service all nodes
			foreach (SATIEnode node in SATIEnode.sourceInsatances)
			{
				SATIEsource src = (SATIEsource) node;
				src.evalConnections();
			}
			// reset listener flags
			foreach (SATIEnode node in SATIEnode.listenerInsatances)
			{
				node.updatePosFlag = node.updateRotFlag = false;
			}
            _lastUpdate = Time.time;
        }
    }

    public void freeSrcNodesInGroup( string groupName )
    {
        if (!connected) return;

        // iterate backwards to modify collection
        for (int i = SATIEnode.sourceInsatances.Count - 1; i >= 0; i--)
        {           
            SATIEsource src = (SATIEsource)SATIEnode.sourceInsatances[i];
                         
            if (src.group.Equals(groupName))
            {
                Debug.Log(GetType() + ".freeSrcNodesInGroup():   deleting node: " + src.nodeName + "  in group: " + src.group);                 
                SATIEnode.sourceInsatances.RemoveAt(i);
                src.deleteNode(src.nodeName);                 
            }
         }
//  no need to do this brute force
//        Debug.Log(GetType() + ".freeSrcNodesInGroup():  telling renderer to kill all nodes in group: " + groupName);  
//        string path = "/a.renderer";
//        OSCMessage message = new OSCMessage (path);
//        message.Append("freeSynths");
//        message.Append(groupName);
//        sendOSC (message);
    }







    void OnDestroy()
	{
//        Debug.Log("SATIEsetup.OnDestroy");
//        OSCMessage message = new OSCMessage ("/spatosc/core");
//        message.Append ("clear");
//        sendOSC (message);
	}




    public void OnApplicationQuit(){
        Debug.Log("SATIEsetup.OnApplicationQuit:  APP QUIT");
        Debug.Log("SATIEsetup.OnDestroy");
        OSCMessage message = new OSCMessage ("/spatosc/core");
        message.Append ("clear");
        sendOSC (message);

        //disconnect();  don't need this

    }
    
    public void disconnect() {
        if (sender!=null){
            sender.Close();
        }
         sender = null;
        connected = false;
    }
    

    // expand this to take multiple messages -- e.g.  mess[]
    public static int sendOSC( OSCMessage mess ) {

        if (sender == null)
        {
            Debug.LogError("SATIEsetup.sendOSC():  OSC sender not defined, skipping message: "+mess.Address);
            return(0);
        }

        int bytesSent = 0;

        OSCBundle objectBundle = new OSCBundle();
        objectBundle.Append(mess);
        bytesSent = sender.Send(objectBundle);
        return (bytesSent);
    }

//    built-in directivity tables:
//        omni
//        cardioid
//        hypercardioid
//        hemisphere
//        cone

//void DllExport debugPrint();
//void DllExport setSynchronous(bool synchronous);
//bool DllExport flushMessages();
//bool DllExport connect(char *fromNode, char *toNode);
//bool DllExport createListener(char *nodeName);
//bool DllExport createGroup(char *nodeName);
//bool DllExport createSource(char *nodeName, char *uriName);
//bool DllExport deleteNode(char *nodeName);
//bool DllExport clearScene();
//bool DllExport addTranslator(char *name, char *type, char *address);
//bool DllExport removeTranslator(char *name);
//bool DllExport disconnect(char *fromNode, char *toNode);
//bool DllExport setAutoConnect(bool enabled);
//bool DllExport setConnectFilter(char *filterRegex);
//bool DllExport setDefaultDistanceFactor(float factor, bool updateExisting);
//bool DllExport setDefaultDopplerFactor(float factor, bool updateExisting);
//bool DllExport setDefaultDirectivityFactor(float factor, bool updateExisting);
//bool DllExport setOrientation(char *node, float pitch, float roll, float yaw);
////bool setNodeOrientation(char *node, float pitch, float roll, float yaw);  // name changed for consistancy
//bool DllExport setPosition(char *node, float x, float y, float z);
//bool DllExport setPositionAED(char *node, float angle , float elevation , float distance );
//bool DllExport setRadius(char *node, float radius );
//bool DllExport setTransitionRadiusFactor(char *node, float factor );
//bool DllExport hasTranslator(char *node);
//bool DllExport setTranslatorVerbose(char *node, bool verbose);
//bool DllExport setNodeStringProperty(char *node, char *key, char *value);
//bool DllExport removeNodeStringProperty(char *node, char *key);

    public static bool createSource(string nodeName, string uriString, string groupName)
    {
        int result;
        string path = "/spatosc/core";
        OSCMessage message = new OSCMessage (path);
        message.Append("createSource");
        message.Append(nodeName);
        message.Append(uriString);
        message.Append(groupName);

        result = sendOSC(message);

        if (result == 0)
            return false;
        else
            return true;
    }

    public static bool createListener(string nodeName, string uriString)
    {
        int result;
        string path = "/spatosc/core";
        OSCMessage message = new OSCMessage (path);
        message.Append("createListener");
        message.Append(nodeName);
        message.Append(uriString);

        
        result = sendOSC(message);
        
        if (result == 0)
            return false;
        else
            return true;
    }

    public static bool createGroup(string nodeName)
    {
        int result;
        string path = "/spatosc/core";
        OSCMessage message = new OSCMessage (path);
        message.Append("createGroup");
        message.Append(nodeName);
        
        result = sendOSC(message);
        
        if (result == 0)
            return false;
        else
            return true;
    }


//	// Much Better version!!  NEEDS TESTING 
//	public  void sendEvent (string keyWord, List<object> values)
//	{
//		string path = "/spatosc/core/"+nodeType+"/" + nodeName + "/event";
//		List<object> items = new List<object>();
//		
//		items.Add(keyWord);
//		
//		foreach (object o in values)
//			items.Add(o);
//		
//		SATIEsetup.OSCtx(path, items);
//		items.Clear();
//	}


    public static bool OSCtx(string path, List<object> items)
    {
        OSCMessage message = new OSCMessage (path);
        int result;

       // Debug.Log("OSCtx: "+path+"  "+items);

        foreach (object value in items)
        {
            //Debug.Log("OSCtx: " + value);
            message.Append(value);
        }
        result = sendOSC(message);
        if (result == 0)
            return false;
        else
            return true;
        
    }


    public static void OSCdebug (string path, string val)
    {
        if (!debugMessTx_static)
            return;
        OSCMessage message = new OSCMessage (path);
        message.Append(val);
        sendOSC(message); 
    }

    public static void OSCdebug (string path, float val)
    {
        if (!debugMessTx_static)
            return;
        OSCMessage message = new OSCMessage (path);
        message.Append(val);
        sendOSC(message); 
    }

    public static void OSCdebug (string path, List <object> items)
    {
        if (!debugMessTx_static)
            return;
        OSCMessage message = new OSCMessage (path);
        foreach (object value in items)
        {
            message.Append(value);
        }
        sendOSC(message); 
    }




//    public bool setNodeProperty(char *node, char *key, float value)
//    {
//        OSCMessage message = new OSCMessage ("/spatosc/core/listener/" + node + "/prop");
//        message.Append (key);
//        message.Append (value);
//        sendOSC (message);
//    }
//    public bool setNodeProperty(char *node, char *key, string value)
//    {
//        OSCMessage message = new OSCMessage ("/spatosc/core/listener/" + node + "/prop");
//        message.Append (key);
//        message.Append (value);
//        sendOSC (message);
//    }

}


//bool DllExport removeNodeIntProperty(char *node, char *key);
//bool DllExport setNodeFloatProperty(char *node, char *key, float value);
//bool DllExport removeNodeFloatProperty(char *node, char *key);
//void DllExport setSceneTranslation(float tx, float ty, float tz);
//void DllExport setSceneOrientation(float pitch, float roll, float yaw);
//void DllExport setSceneOrientationQuat(float x, float y, float z, float w);
//void DllExport setSceneScale(float sx, float sy, float sz);
//bool DllExport setDistanceFactor(char *sourceNode, char *sinkNode, float factor);
//bool DllExport setDopplerFactor(char *sourceNode, char *sinkNode, float factor);
//bool DllExport setDirectivityFactor(char *sourceNode, char *sinkNode, float factor);
//bool DllExport setIncidenceFactor(char *sourceNode, char *sinkNode, float factor);
//bool DllExport setMaxGainClip(char *sourceNode, char *sinkNode, float db);
//bool DllExport setConnectionMute(char *sourceNode, char *sinkNode, bool enable);
//bool DllExport setNodeActive(char *node, bool enable);
//bool DllExport setVerbose(bool enable);
//bool DllExport setURI(char *node, char *uri);
//bool DllExport sendNodeEvent(char *node,  char *key, char *CommaDelimitedValuesString);
//bool DllExport setDirectivity(char *sourceNode, char *lateralTableName, char *verticalTableName);
//bool DllExport addMember(char *groupStr, char *sourceStr);
//bool DllExport dropMember(char *groupStr, char *sourceStr);

/*
 * 
 * CORE 
     /spatosc/core createSource  nodeName uriPath<or emptyString>  groupName<or emptyString>
    /spatosc/core createListener nodeName

    /spatosc/core createGroup nodeName
    /spatosc/core deleteNode nodeName
    /spatosc/core connect srcNode listenerNode
    /spatosc/core disconnect srcNode listenerNode
    /spatosc/core clear
    
    NODE messages
    
    /spatosc/core/listener/nodeName/uri  type://name  (e.g.  plugin://testnoise~ )
    /spatosc/core/listener/nodeName/prop keyword value(s) (string, float or int)     
    /spatosc/core/listener/nodeName/state value  // 1=DSP_active 0=DSP_inactive
    /spatosc/core/listener/nodeName/event  eventName <opt> atom1 atom2...atomN      
    
    /spatosc/core/source/nodeName/uri  type://name  (e.g.  plugin://testnoise~ )
    /spatosc/core/source/nodeName/prop keyword value(s) (string, float or int)     
    /spatosc/core/source/nodeName/state value  // 1=DSP_active 0=DSP_inactive
    /spatosc/core/source/nodeName/event  eventName <opt> atom1 atom2...atomN    
    
    /spatosc/core/group/nodeName/uri  type://name  (e.g.  plugin://testnoise~ )
    /spatosc/core/group/nodeName/prop keyword value(s) (string, float or int)     
    /spatosc/core/group/nodeName/state value  // 1=DSP_active 0=DSP_inactive
    /spatosc/core/group/nodeName/event  eventName <opt> atom1 atom2...atomN    
    
    CONNECTION messages
    
    /spatosc/core/connection/sourceNode->listenerNode/update azimuthRADIANS elevationRADIANS gainDB delayMS  lpHZ   
    /spatosc/core/connection/sourceNode->listenerNode/spread  value  // exponent for incidence effect:  0 = no effect;  1 = normal;   >1 = more intense               
    
    GROUP messages
    
    /spatosc/core/group/nodeName/add sourceNode
    /spatosc/core/group/nodeName/drop  sourceNode
        
*/