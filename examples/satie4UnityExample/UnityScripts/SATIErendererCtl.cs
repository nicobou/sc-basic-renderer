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
using System.IO;
using System.Threading;
using System.Collections;
using System.Collections.Generic;
using System.Net;

using OSC.NET;

public class SATIErendererCtl : MonoBehaviour
{
	
    public bool dspState = true;
    private bool _dspState;

    public string projectName = "default";

    public string projectDir;
    // defaults to $PROJECT/StreamingAssets
    private string _projectDir;

    [Range(-90f, 18)]
    public float outputGainDB = -10f;
    private float _outputGainDB;
    
    [Range(-24f, 24)]
    public float outputTrimDB = -0f;
    private float _outputTrimDB;
    
    public bool dim = false;
    private bool _dim;
    
    public bool mute = false;
    private bool _mute;

    //private bool _start = false;


    public string outputFormat = "stereo";
    // builtin choices:  stereo quad five.one seven.one octo dome mono labodome
    private string _outputFormat;

    private string _oscMessage = "/a.renderer";

    private OSCTransmitter sender = null;
    private bool connected = false;
    //private Thread thread;

    private SATIEsetup SATIEsetupCS;

    public int port = 18032;
    //MH faceShiftOSC default port
    public string address = "localhost";
    // defalut to localhost
    

    public void UnityOSCTransmitter()
    {
    }

    public int getPort()
    {
        return port;
    }

    public void Awake()
    {
        //Debug.Log(string.Format("{0}.Awake(): called", GetType()), transform);


        SATIEsetupCS = transform.GetComponent<SATIEsetup>();   // look for SATIEsetup component in this transform
        
        if (!SATIEsetupCS)
        {
            Debug.LogWarning("SATIErendererCtl.Awake: SATIEsetup class component not found in " + transform.name + " :  Using local address and port");
        }
        else
        {
            port = SATIEsetupCS.RendererPort; //MH faceShiftOSC default port
            address = SATIEsetupCS.RendererAddress;  // defalut to localhost
        }
        
        try
        {
            Debug.Log("SATIErendererCtl.Awake: sending to " + address + ":" + port);
            connected = true;
            sender = new OSCTransmitter(address, port);
            //thread = new Thread(new ThreadStart(listen));
            //thread.Start();
        }
        catch (Exception e)
        {
            Debug.LogError("SATIErendererCtl.Awake: OSC failed to connect to " + address + ":" + port + " cannot initialize component");
            Debug.LogError(e.Message);
            connected = false;
            sender = null;
            return;
        }
        string localHostName = Dns.GetHostName();
        IPHostEntry hostEntry = Dns.GetHostEntry(localHostName);
        foreach (IPAddress ipAddr in hostEntry.AddressList)
        {
            Debug.Log("SATIErendererCtl.Awake: MY IP:" + ipAddr.ToString());
        }

        _dspState = dspState;
        _outputGainDB = outputGainDB;
        _dim = dim;
        _outputTrimDB = outputTrimDB;
        _mute = mute;
        _outputFormat = outputFormat;

        updateProjectDir();
        updateGainDB();
        updateTrimDB();
        updateMute();
        updateOutputFormat();
    }


    private bool reconnet2renderer()
    {
        if (sender != null)
            return true;
        try
        {
            Debug.Log("SATIErendererCtl.reconnet2renderer(): sending to " + address + ":" + port);
            connected = true;
            sender = new OSCTransmitter(address, port);
            //thread = new Thread(new ThreadStart(listen));
            //thread.Start();
        }
        catch (Exception e)
        {
            Debug.LogError("SATIErendererCtl.reconnet2renderer(): OSC failed to connect to " + address + ":" + port + " cannot initialize component");
            Debug.LogError(e.Message);
            connected = false;
            sender = null;
            return false;
        }
        string localHostName = Dns.GetHostName();
        IPHostEntry hostEntry = Dns.GetHostEntry(localHostName);
        foreach (IPAddress ipAddr in hostEntry.AddressList)
        {
            Debug.Log("SATIErendererCtl.reconnet2renderer(): MY IP:" + ipAddr.ToString());
        }
        return true;
    }



 
    private void updateDSPstate()
    {
        OSCMessage message = new OSCMessage(_oscMessage);
        float state = (dspState) ? 1f : 0f;
        
        message.Append("setDSP");
        message.Append(state);
        sendOSC(message);
    }

    private void updateProjectDir()
    {
        string path = "";

        //Debug.Log ("PROJECT DIR: "+ projectDir);

        if (projectDir == "")
        {
            return;   // if no project path is provided, use the one that is definied in the satie server project

//            _projectDir = projectDir = "../StreamingAssets";
//            path = Application.streamingAssetsPath;
            // Debug.Log ("projectDir EMPTY,  path= "+ path);
        }
        else if (projectDir.StartsWith("$DROPBOX"))    // users can specify $DROPBOX, and assuming a standard filepath like  "C:\Users or /Users,  we replace /Users/name with "~"
        {
            string[] pathItems;
//			int dirIndex = 0; // Never used warning
            string relPath = "~";
            int counter = 0;
            int usersIndex = 0;
//			int dropBoxIndex = 0; // Never used warning
            char delimiter = '/';  // Path.DirectorySeparatorChar;   NOT NEEDED FOR WINDOWS ANYMORE


            // will default to this if there are errors
            _projectDir = projectDir = "../StreamingAssets";
            path = Application.streamingAssetsPath;


            //Debug.Log("***************************** PATH= "+path);

            if (!path.Contains("Dropbox") || (!path.Contains("Users") && !path.Contains("Utilisateurs")))
            {
                Debug.LogWarning("SATIErendererCtl.updateProjectDir: no DROPBOX and/or /Users directory found, setting project path to default");
                return;
            }

            pathItems = path.Split(delimiter);   // get array of directory items
 
            counter = 0;
            foreach (string s in pathItems)
            {
                if (s == "Users" || s == "Utilisateurs")
                {
                    usersIndex = counter;
                    break;
                }
                counter++;
            }

            if (pathItems.Length < usersIndex + 3)   // /users/name/relativestuff.....
            {
                Debug.LogError("SATIErendererCtl.updateProjectDir: poorly formated directory path (BUG??), setting project path to default");
                return;
            }

            for (int i = usersIndex + 2; i < pathItems.Length; i++)
            {
                relPath += "/" + pathItems[i];
            }
            //Debug.Log("***************************** pathItems[0] = " + pathItems[0]);
            // Debug.Log("RELPATH= "+relPath);
            _projectDir = projectDir = relPath;
            path = relPath;
        }
        else if (projectDir.StartsWith("/"))
            path = projectDir;
        else
            path = Application.streamingAssetsPath + "/" + projectDir;


        OSCMessage message = new OSCMessage(_oscMessage);
		
        message.Append("setProjectDir");
        message.Append(path);
        sendOSC(message);
    }

    public float getOutputDB()
    {
        return outputGainDB;
    }


    public void setOutputDB(float db)
    {
        _outputGainDB = outputGainDB = db;
        updateGainDB();
    }

    private void updateGainDB()
    {
        OSCMessage message = new OSCMessage(_oscMessage);
        
        message.Append("setOutputDB");
        message.Append(outputGainDB);
        sendOSC(message);
    }

 
    public void setOutputTrimDB(float db)
    {
        _outputTrimDB = outputTrimDB = db;
        updateTrimDB();
    }

    private void updateTrimDB()
    {
        OSCMessage message = new OSCMessage(_oscMessage);
        
        message.Append("setOutputTrimDB");
        message.Append(outputTrimDB);
        sendOSC(message);
    }

    public void setOutputMute(float state)
    {
        _mute = mute = (state > 0);
        updateMute();
    }

    private void updateMute()
    {
        OSCMessage message = new OSCMessage(_oscMessage);
        float state = (mute) ? 1f : 0f;
        
        message.Append("setOutputMute");
        message.Append(state);
        sendOSC(message);
    }

    public void setOutputDIM(float state)
    {
        _dim = dim = (state > 0);
        updateDim();
    }

    private void updateDim()
    {
        OSCMessage message = new OSCMessage(_oscMessage);
        float state = (dim) ? 1f : 0f;
        
        message.Append("setOutputDIM");
        message.Append(state);
        sendOSC(message);
    }

    private void updateOutputFormat()
    {
        OSCMessage message = new OSCMessage(_oscMessage);
        message.Append("setOutputFormat");
        message.Append(outputFormat);
        sendOSC(message);
    }

    // only three message value types
    public void projectMess(string key)
    {
        string OSCaddress = "/satie/" + projectName;
        OSCMessage message = new OSCMessage(OSCaddress);
 
        Debug.Log(transform.name + " " + GetType() + "sending projectMess:    project: " + OSCaddress + "   key: " + key);

        message.Append(key);
        sendOSC(message);
    }


    public void projectMess(string key, float val)
    {
        string OSCaddress = "/satie/" + projectName;
        OSCMessage message = new OSCMessage(OSCaddress);

        Debug.Log(transform.name + " " + GetType() + "sending projectMess:    project: " + OSCaddress + "   key: " + key);
        message.Append(key);
        message.Append(val);
        sendOSC(message);
    }

    public void projectMess(string key, string val)
    {
        string OSCaddress = "/satie/" + projectName;
        OSCMessage message = new OSCMessage(OSCaddress);

        Debug.Log(transform.name + " " + GetType() + "sending projectMess:    project: " + OSCaddress + "   key: " + key);
        message.Append(key);
        message.Append(val);
        sendOSC(message);
    }

    /**
	 * Call update every frame in order to dispatch all messages that have come
	 * in on the listener thread
	 */
    public void Update()
    {

//        if (Input.GetKeyDown ("d")) {
//
//            OSCMessage message = new OSCMessage ("/a.renderer/setOutputDB");
//			//message.Append ("fuckme");
//			message.Append (-12f);
//			sendOSC (message);
//			//Debug.Log("send mess");
//		}

    }

    // called when inspector's values are modified
    public virtual void OnValidate()
    {
//        if (!_start)
//            return;
        
        if (!connected)
            return;
		
        if (_projectDir != projectDir)
        {
            _projectDir = projectDir;
            updateProjectDir();
        }

        if (_outputGainDB != outputGainDB)
        {
            _outputGainDB = outputGainDB;
            updateGainDB();
        }
		
        if (_outputTrimDB != outputTrimDB)
        {
            _outputTrimDB = outputTrimDB;
            updateTrimDB();
        }
		
        if (_outputFormat != outputFormat)
        {
            _outputFormat = outputFormat;
            updateOutputFormat();
        }
	
        if (_dim != dim)
        {
            _dim = dim;
            updateDim();
        }
		
        if (_mute != mute)
        {
            _mute = mute;
            updateMute();
        }
		
        if (_dspState != dspState)
        {
            _dspState = dspState;
            updateDSPstate();
        }
		
		
    }


    public void OnApplicationQuit()
    {

//        OSCMessage message = new OSCMessage ("/spatosc/core");
//        //message.Append ("fuckme");
//        message.Append ("clear");
//        sendOSC (message);
//        Debug.Log("APP QUIT");
        disconnect();
    }

    public void disconnect()
    {
        if (sender != null)
        {
            sender.Close();
        }
      	
        sender = null;
        connected = false;
    }

    public bool isConnected()
    {
        return connected;
    }


    // expand this to take multiple messages -- e.g.  mess[]
    public int sendOSC(OSCMessage mess)
    {
        int bytesSent = 0;

        if (sender != null)
        {
            OSCBundle objectBundle = new OSCBundle();
            objectBundle.Append(mess);
            bytesSent = sender.Send(objectBundle);
            return (bytesSent);
        }
        else
        {
            Debug.LogError("SATIErendererCtl.sendOSC: OSC not initialized, can't send message");
            return(bytesSent);
        }
    }



    //	public static OSCMessage setMessage(int s, int i, float x, float y, float a, float xVec, float yVec, float A, float m, float r)
    //	{
    //		OSCMessage message = new OSCMessage("/tuio/2Dobj");
    //		message.Append("set");
    //		message.Append(s);
    //		message.Append(i);
    //		message.Append(x);
    //		message.Append(y);
    //		message.Append(a);
    //		message.Append(xVec);
    //		message.Append(yVec);
    //		message.Append(A);
    //		message.Append(m);
    //		message.Append(r);
    //		return message;
    //	}

}
