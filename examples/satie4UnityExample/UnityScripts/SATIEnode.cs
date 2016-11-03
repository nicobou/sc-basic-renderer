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
//using System;
using System.IO;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using OSC.NET;
using System.Linq;


//public abstract class oscMess
//{
//    string keyword { get;  set; }
//    string message { get; set; }
//}

public class SATIEnode : MonoBehaviour
{

    public bool debug = false;

    public bool nodeEnabled = true;
    private bool _state;

    private bool _start = false;



 
    public string AssetPath = "unused";
    // subdirectory of Assets/StreamingAssets
    private string _assetPath = "";

    public string uri = "plugin://default";

    public List <string> PropertyMessages = new List<string>();
    private List <string> _PropertyMessages = new List<string>();
    // used to detect changes in the Inspector

    [Header("Node Update Settings")]
	 
   
    public bool UpdateUsingChangeThresh = false;
    public float angleThresh = 5f;
    public float movementThresh = .05f;
    private float _movementThreshSqu;
 

    // used internally for node's scenegraph update status
    private Quaternion _lastSpatUpdateRotation;
    private Vector3 _lastSpatUpdatePos;
    private Vector3 _lastPos;
    private Quaternion _lastRot;
    //private float _lastUpdateTime = 0f;
    
    [HideInInspector] 
    public bool updateRotFlag = false;

    [HideInInspector] 
    public bool updatePosFlag = false;

    [HideInInspector] 
    public static List<SATIEnode> sourceInsatances = new List<SATIEnode>();

    [HideInInspector] 
    public static List<SATIEnode> listenerInsatances = new List<SATIEnode>();

    [HideInInspector] 
    public static List<SATIEnode> groupInsatances = new List<SATIEnode>();


    [HideInInspector] 
    static public int nodeCount = 0;
    //  nodes cereated since game start
    
    [HideInInspector] 
    public string nodeName = "noName";
    
    //[HideInInspector]
    //public int nodeNo;

    [HideInInspector] 
    public string nodeType = "source";



    // called when inspector's values are modified
    public virtual void OnValidate()
    {

        if (!_start)
            return;
  
        // Debug.LogError("SATIEnode.OnValidate() for source: " + nodeName);


        if (_state != nodeEnabled)
        {
            _state = nodeEnabled;
            setNodeActive(nodeName, nodeEnabled);
        }



        if (_PropertyMessages.Count != PropertyMessages.Count)
        {
            // Debug.Log("_PropertyMessages.Count != PropertyMessages.Count");


            _PropertyMessages.Clear();
            foreach (string s in PropertyMessages)
            {
                _PropertyMessages.Add(s);
            }
            return;
        }

        for (int i = 0; i < PropertyMessages.Count; i++)
        {
            // Debug.Log("PropertyMessages [i]:  " + PropertyMessages [i]);
            if (PropertyMessages[i] != _PropertyMessages[i])
            {
                List<string> property = new List<string>(PropertyMessages[i].Split(' '));
                string keyword = "";
                string svalue = "";
 
                //Debug.Log("CHANGED PropertyMessages [i]:  " + PropertyMessages [i]);
 
                // remove spaces
                for (int n = 0; n < property.Count; n++)
                {
                    if (keyword == "" && property[n] != "")
                    {
                        keyword = property[n];

                        // if (n == property.Count) break;

                        for (int t = n + 1; t < property.Count; t++)
                        {
                            if (svalue == "" && property[t] != "")
                            {
                                svalue = property[t];
                                break;
                            }
                        }

                    }
                }

                // Debug.Log("\t \t \t WE GOT:  MODIFIED PROPERTY: "+keyword+" : "+ svalue);
                //  Debug.Log("\t PROPERTY len = " + property.Count);
                //            foreach (string item in property)   Debug.Log("\t PROPERTY ATOM: " + item);       

                // if incomplete property abort
                if (keyword == "" || svalue == "")
                {
                    //Debug.Log("propseryMessage too short:  " + PropertyMessages [i]);
                    return;
                }

                // else the property is valid

                // rewrite property without white spaces
                PropertyMessages[i] = keyword + " " + svalue;

                _PropertyMessages[i] = PropertyMessages[i];


                //Debug.Log("MODIFIED PROPERTY: "+keyword+" : "+svalue);
                
                if (keyword != " " && svalue != " " && svalue != ".")
                {
                    //Debug.Log("\t \t \t sendOSCprop: "+keyword+" : "+ svalue);
                    sendOSCprop(keyword, svalue);
                }
            }
        }
    }


    public virtual  void Awake()
    {
        _start = false;

        foreach (string s in PropertyMessages)
        {
            _PropertyMessages.Add(s);
        }
        if (uri == "")
        {
            uri = "plugin://default";
            Debug.LogWarning("SATEnode.Awake: node:" + nodeName + " URI string is empty, setting URI to default plugin");
        }
    }


	
    public virtual  void Start()
    {
        _start = true;

        // createNode(); must have already been called from subclass "Start()" method
        _lastRot = _lastSpatUpdateRotation = (Quaternion)transform.rotation;
        _lastPos = _lastSpatUpdatePos = transform.position;
        _movementThreshSqu = movementThresh * movementThresh;


        // Vector3 orientation = transform.rotation.eulerAngles;
        //SATIEsetup.setPositionWrapper(nodeName,transform.position.x, transform.position.y, transform.position.z);
        //SATIEsetup.setOrientation(nodeName, orientation.x, orientation.y, orientation.z);
        //StartCoroutine(testTrigger());

        // Debug.Log("SATIEnode.Start:  AssetPath = " + _assetPath);
        //updatePosFlag = true;  
        //updateRotFlag = true;
        // Debug.LogError("SATIEnode.Start() for source: " + nodeName);
    }


    void OnEnable()
    {
        if (!_start)
            return;
        if (nodeEnabled)
            setNodeActive(nodeName, true);
    }

    void OnDisable()
    {
        if (!_start)
            return;
        if (nodeEnabled)
            setNodeActive(nodeName, false);
    }



    public void setActive(bool state)
    {
        _state = nodeEnabled = state;
        setNodeActive(nodeName, nodeEnabled);
    }

    void OnApplicationPause(bool pauseStatus)
    {
        //Debug.Log("PAUSED");
    }

    // called from subclass "Start()" method
    public bool initNode()
    {
        bool result = false;
        string uriString;


        if (!SATIEsetup.OSCenabled)
        {
            Debug.LogWarning(transform.name + ":  SATIEnode.Start:  SATIEsetup: translator(s) not enabled");
            //return false;
        }

        List <SATIEnode> nodeList = new List<SATIEnode>();


        switch (nodeType)
        {
            case "listener":
                nodeList = listenerInsatances;
                break;
            case "source":
                nodeList = sourceInsatances;
                break;
            case "group":
                nodeList = groupInsatances;
                break;
        }

        foreach (SATIEnode node in nodeList)
        {
            if (transform.name == node.name)
            {
                transform.name = transform.name + "_" + transform.GetInstanceID();  
                Debug.LogWarning("SATIEnode: initNode:  duplicate node name found. Renaming node: " + transform.name);
            }
        }
        nodeList.Add((SATIEnode)this);


        //nodeNo = nodeCount++;

        if (!uri.Equals(""))
        {
            if (AssetPath != "" && AssetPath != "unused")   // insert the full path in the URI message
            {
                _assetPath = Application.streamingAssetsPath + Path.DirectorySeparatorChar + AssetPath;
				
                uriString = uri.Replace("//", "//" + _assetPath + Path.DirectorySeparatorChar);
            }
            else
                uriString = uri;
			

        }
        else
            uriString = "";
        //Debug.Log("********************************************initNode: node: "+transform.name+"   URI : " + uriString);
            


        //Debug.Log("URI STRING: "+uriString);

        if (nodeType == "listener")
        {
            nodeName = transform.name; // + "_" + nodeNo;
            result = SATIEsetup.createListener(nodeName, uriString);
            sendUri(uriString); // not really used but .....
        } 

		// this should be done in the superclass-- 
		else if (nodeType == "source")
        {
            SATIEsource src = (SATIEsource)this;

            // go agead an make this node with this group name, even if the group has not been created yet
            //string groupName = "";
//
//			if (gameObject.tag != "Untagged")  
//				groupName = gameObject.tag;

            nodeName = transform.name;  // + "_" + nodeNo;
            result = SATIEsetup.createSource(nodeName, uriString, src.group);
            //sendUri(uriString);   //NO NEED TO DO THIS NOW THAT THE URI IS CREATED WITH THE SOURCE
            //Debug.Log("******************************************SATIEnode.initNode: source nodename; "+nodeName+"  groupName: "+ src.group);
        }
        else if (nodeType == "group")
        {
            // do nothing, this is done in the group class
        }
        else
        {
            Debug.LogWarning("SATIEnode.initNode: nodetype not recognized");
            return false;
        }

        _state = nodeEnabled;
        // moved to initProperties
//       setNodeActive(nodeName, nodeEnabled);
        
        //Debug.Log("SATIEnode.Update: CREATING SPAT_OSCNODE: "+nodeName);

        //sendProperties();

        SATIEsetup.SATIEnodeList.Add(this);

        transform.name = nodeName;  // overwrite node name with spatOSC unique name



        StartCoroutine(initProperties());

        return result;
    }


    IEnumerator initProperties() // this is delayed to make sure the audio renderer has time to create the node beforehand
    {
        yield return new WaitForFixedUpdate();
        //yield return new WaitForSeconds(.05f);

        setNodeActive(nodeName, nodeEnabled);

        sendProperties();
        
    }



    // OLD STYLE - NEEDS TO BE REDONE
    public void sendEvent(string keyWord, string CommaDelimitedValuesString)
    {
        int ivalue;
        float fvalue;
        string path;

        List<string> values = new List<string>(CommaDelimitedValuesString.Split(','));
        //names.Reverse();

        List<object> items = new List<object>();

        path = "/spatosc/core/" + nodeType + "/" + nodeName + "/event";
        
        
        items.Add(keyWord);

        
        foreach (string svalue in values)
        {
            if (int.TryParse(svalue, out ivalue))
            {
                //Debug.Log("ITEM IS AN INTEGER = " + ivalue);
                items.Add(ivalue);
            }
            else if (float.TryParse(svalue, out fvalue))
            {
                //Debug.Log("ITEM IS A FLOAT = " + fvalue);
                items.Add(fvalue);
            }
            else
            {
                //Debug.Log("ITEM IS A STRING = " + svalue);
                items.Add(svalue);
            }
        }
 
        SATIEsetup.OSCtx(path, items);
        items.Clear();
    }

  
    public void sendEvent(List<object> items)   // items contains keyword data1 data2..... dataN
    {


        string path;

        path = "/spatosc/core/" + nodeType + "/" + nodeName + "/event";
  
        string sheefa = "";

        foreach (object o in items)
        {
            sheefa += o.ToString();
            sheefa += "";
        }
 
		
        //Debug.Log(transform.name + " : " + GetType() + " : " + "sendEvent: "+path+" : "+sheefa  );


        SATIEsetup.OSCtx(path, items);
        //items.Clear();
    }



    public virtual void  setNodeActive(string nodeName, bool state)
    {
        string path = "/spatosc/core/" + nodeType + "/" + nodeName + "/state";
        List<object> items = new List<object>();
        
        if (state)
            items.Add(1);
        else
            items.Add(0);
              
        SATIEsetup.OSCtx(path, items);
        items.Clear();
    }


    public virtual void deleteNode(string nodeName)
    {
        string path = "/spatosc/core";
        List<object> items = new List<object>();

        items.Add("deleteNode");
        items.Add(nodeName);        

        SATIEsetup.OSCtx(path, items);
        items.Clear();

    }
        
    // DANGER:  no uriString format checking
    public  void setUri(string uriString)
    {

        uri = uriString;
        if (_start)
        {
            sendUri(uriString);
            sendProperties();
            updatePosFlag = true;
            updateRotFlag = true;
        }
    }

    public void sendUri(string uriString)
    {
     
        string path = "/spatosc/core/" + nodeType + "/" + nodeName + "/uri";
        List<object> items = new List<object>();

        items.Add(uriString);        
        SATIEsetup.OSCtx(path, items);
        items.Clear();
    }



    // Update is called once per frame
    public virtual void Update()
    {
        //if (Input.GetKeyDown("s")) sendProperties();
        //if (Input.GetKeyDown("a")) sendEvent("sheefa", "1,2,-3,4.1");
    }


    public virtual void FixedUpdate()
    {
		 
    }


    // lateUpdate is called onece per frame, after physics engine is updated
    public virtual void LateUpdate()
    {
        updateNode(); 
    }
	


   
    // called to set node's update flags
    void updateNode()
    {
        if (UpdateUsingChangeThresh)  // filter by amount of change since last spatOSC update
        {
            float angleDif = Quaternion.Angle(transform.rotation, _lastSpatUpdateRotation);
            float positionDif = Vector3.SqrMagnitude(transform.position - _lastSpatUpdatePos);

            if (positionDif > _movementThreshSqu)
            {
                //SATIEsetup.setPositionWrapper(nodeName,transform.position.x, transform.position.y, transform.position.z);
                updatePosFlag = true;
                _lastSpatUpdatePos = transform.position;   
                if (debug)
                    Debug.Log("SATIEnode.Update: filter mode update position for " + nodeName);
            }     

            if (angleDif > angleThresh || angleDif < -angleThresh)
            {
                Vector3 orientation = transform.rotation.eulerAngles;

                //SATIEsetup.setOrientation(nodeName, orientation.x, orientation.y, orientation.z); 
                updateRotFlag = true;
                _lastSpatUpdateRotation = (Quaternion)transform.rotation;
                if (debug)
                    Debug.Log("SATIEnode.Update: " + nodeName + " orientation = " + orientation);
            }
        }
        else  // Else just simple change filter   (any change at all)
        {
            if (transform.position != _lastPos)
            {
                //SATIEsetup.setPositionWrapper(nodeName,transform.position.x, transform.position.y, transform.position.z);
                updatePosFlag = true;
                _lastPos = transform.position;
                if (debug)
                    Debug.Log("SATIEnode.Update: filter mode update position for " + nodeName);
            }
            
            if (_lastRot != (Quaternion)transform.rotation)
            {
                Vector3 orientation = transform.rotation.eulerAngles;
                
                //SATIEsetup.setOrientation(nodeName, orientation.x, orientation.y, orientation.z);
                updateRotFlag = true;
                _lastRot = (Quaternion)transform.rotation;
                
                if (debug)
                    Debug.Log("SATIEnode.Update: " + nodeName + " orientation = " + orientation);
            }
        }
        //Debug.Log("spatOECnode.updateNode: time delta:" + (Time.realtimeSinceStartup - _lastUpdateTime));
        //  _lastUpdateTime = Time.realtimeSinceStartup;
    }

    void OnDestroy()
    {
        if (SATIEsetup.OSCenabled)
        {

            // SATIEnode node = (SATIEnode) this;

            SATIEsetup.SATIEnodeList.Remove(this);

            switch (nodeType)
            {
				
                case  "listener": 
                    listenerInsatances.Remove(this);
                    break;
                case  "source":
                    sourceInsatances.Remove(this);
                    break;
                case "group":
                    groupInsatances.Remove(this);
                    break;
            }

            deleteNode(nodeName);
        }
    }


    // prints a warning message and returns empty string if property is not found
    public string getStrProperty(string propName)
    {

        foreach (string s in PropertyMessages)
        {

            if (!s.StartsWith(propName)) continue;


            List<string> items = new List<string>(s.Split(' '));
            foreach (string item in items)
            {
                if (item.Equals(' '))
                    continue;
                
                return item;
            }
        }
        Debug.LogWarning(transform.name + " " + GetType() + ":getProperty() prop: " + propName + " not able to match property, and or: bad value format, must be a string"); 
        return "";
    }

    // prints a warning message and returns zero if property is not found
    public float getFloatProperty(string propName)
    {

        foreach (string s in PropertyMessages)
        {

            if (!s.StartsWith(propName)) continue;


            List<string> items = new List<string>(s.Split(' '));
            foreach (string item in items)
            {
                int ival;
                float fval;
                double dval;

                if (item.Equals(' '))
                    continue;

                if (int.TryParse(item, out ival))
                    return (float)ival;
                else if (float.TryParse(item, out fval))
                    return fval;
                else if (double.TryParse(item, out dval))
                    return (float)dval;
            }
        }
        Debug.LogWarning(transform.name + " " + GetType() + ":getProperty() prop: " + propName + " not able to match property, and or: bad value format, must be a float"); 
        return 0f;
    }


    public void setProperty(string propName, object value)
    {
        string valstr = value.ToString();

        string newProp = propName + " " + valstr;

        foreach (string s in PropertyMessages)
        {
            if (s.Contains(propName))
            {
                PropertyMessages.Remove(s);   // remove old string before appending new one 
                break;
            }
        }
        PropertyMessages.Add(newProp);
        sendOSCprop(propName, valstr);

        //Debug.Log("SATIEnode.setProperty: adding " + newProp);

    }


    public void refreshState()
    {
        string uriString;

        if (!uri.Equals(""))
        {
            if (AssetPath != "" && AssetPath != "unused")   // insert the full path in the URI message
            {
                _assetPath = Application.streamingAssetsPath + Path.DirectorySeparatorChar + AssetPath;
                
                uriString = uri.Replace("//", "//" + _assetPath + Path.DirectorySeparatorChar);
            }
            else
                uriString = uri;
            
            sendUri(uriString);
        }
        sendProperties();
        updatePosFlag = updateRotFlag = true;

    }


    void sendProperties()
    {
        foreach (string s in PropertyMessages)
        {
            if (s.Equals(""))
                continue;

            string keyword = "";
            string svalue = "";
                
 

            //string oscmess = "";
                
            // Debug.Log("rawmess:" + rawmess);
                
            List<string> items = new List<string>(s.Split(' '));

                
            foreach (string item in items)
            {
                if (!item.Equals(' '))
                {
                    if (keyword.Equals(""))
                        keyword = item;
                    else if (svalue.Equals(""))
                        svalue = item;
                    else
                    {
                        Debug.LogWarning(transform.name + ":  SATIEnode.Start: param mess: " + keyword + " ignoring values after " + svalue);
                        break;
                    }
                }
            }
                
            if (!keyword.Equals("") && !svalue.Equals(""))   // keyword and value good, now send the corrensponding properties messages
            {
                sendOSCprop(keyword, svalue);
            }
            else
            {
                Debug.LogWarning(transform.name + ":  SATIEnode.Start: param mess: ignoring incomplete message");
                break;
            }
        }
    }



    public void sendOSCprop(string keyword, string svalue)
    {
        
        List<object> items = new List<object>();

        int ivalue;
        float fvalue = 0;


        string path = "/spatosc/core/" + nodeType + "/" + nodeName + "/prop";

 
        items.Add(keyword);


        
        if (int.TryParse(svalue, out ivalue))
        {
            //Debug.Log("ITEM IS AN INTEGER = " + ivalue);
            items.Add(ivalue);
        }
        else if (float.TryParse(svalue, out fvalue))
        {
            //Debug.Log("ITEM IS A FLOAT = " + fvalue);
            items.Add(fvalue);
        }
        else
        {
            //Debug.Log("ITEM IS A STRING = " + svalue);
            items.Add(svalue);
        }

        //Debug.Log(transform.name + " : " + GetType() + " : " + "sendOSCprop: "+path+" : "+keyword+" : "+fvalue  );

        SATIEsetup.OSCtx(path, items);
        items.Clear();
    }


}
