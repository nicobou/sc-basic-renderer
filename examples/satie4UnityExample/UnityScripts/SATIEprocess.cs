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
using System.Collections;
using System.Collections.Generic;



// note:  this script must be in the transform that the SATIEsourceNode is in, and that node must have a "process" as a uri type
public class SATIEprocess : MonoBehaviour {

	public string processName = "default";

	public List <string> launchArgs = new List<string>();

	public List <string> events = new List<string>();
	private List <string> _events = new List<string>();

	public List <string> parameters = new List<string>();
	private List <string> _parameters = new List<string>();
    private bool _start = false;


	SATIEsource SATIEsourceCS;

	void Awake()
	{
		// string argvec[];
        string argString;

		SATIEsourceCS = transform.GetComponent<SATIEsource>();

		if (SATIEsourceCS == null)
		{
			Debug.LogError("SATIEprocess.start(): component of type <SATIEsource> found in transform, aborting");
			return;
		}

        if (launchArgs.Count == 0)
        {
            SATIEsourceCS.uri = "process://" + processName;
            return;
        }

        // ELSE


        argString =  string.Join(" ", launchArgs.ToArray()); 

        Debug.Log ("SATIEprocess.Awake:  argString: " + argString); 
        //       Debug.Log ("SATIEprocess.Awake:  uriString: " + "process://"+processName+ "_" + argString); 
        SATIEsourceCS.uri = "process://"+processName+ " " + argString;

	}


	// Use this for initialization
	void Start () 
	{
		if (SATIEsourceCS == null)
		{
			Debug.LogError("SATIEprocess.start(): component of type <SATIEsource> found in transform, aborting");
			return;
		}
		// else
        _start = true;
      	StartCoroutine( afterStart() );
	

	}
	
	// Update is called once per frame
	void Update ()
	{
		if (Input.GetKey ("p")) {
			sendState ();
		}
	
	}


	IEnumerator afterStart() // now that litener(s) have been conection related parameters.
	{
		yield return new WaitForFixedUpdate ();
		sendState ();  // by this time, all the start and initialization routines have been evaluated and we can assume that updates to this node will be received on the renderer.


	}

	void sendState ()
	{
		sendEvents (events, false);
		sendEvents (parameters, true);  
	}


	// called when inspector's values are modified
	public virtual void OnValidate()
	{
		validateEvents ();
		validateParams ();

	}




	void validateEvents()
	{
        if (!_start) return;
        
		if (_events.Count != events.Count)
		{
			// Debug.Log("_events.Count != events.Count");


			_events.Clear();
			foreach (string s in events)
			{
				_events.Add(s);
			}
			return;
		}

		for (int i=0; i<events.Count; i++)
		{
			// Debug.Log("events [i]:  " + events [i]);
			if (events [i] != _events [i])
			{
				List<string> property = new List<string>(events [i].Split(' '));
				string keyword = "";
				string svalues = "";


				//Debug.Log("CHANGED events [i]:  " + events [i]);

				// remove spaces
				for (int n = 0; n < property.Count; n++)
				{
                    if (keyword == "")
                    {
                        if (property[n] != "")
                            keyword = property[n];
                       continue;
                    }
					else 
					{ 
						if (property [n] != "")
							svalues += " " + property [n];
					}
				}

				//Debug.Log("\t \t \t WE GOT:  MODIFIED EVEMT: "+keyword+" : "+ svalues);
				//Debug.Log("\t EVENT len = " + events.Count);
				//            foreach (string item in property)   Debug.Log("\t PROPERTY ATOM: " + item);       

				// if incomplete event abort
                if (keyword == "" || svalues == "" ) 
				{
					Debug.LogWarning("Event Message too short:  " + events [i]);
					return;
				}

				// else the property is valid

				// rewrite event without white spaces
				//events[i] = keyword + " " + svalue;

				_events [i] = events [i] = keyword + svalues;
				sendEvents (events, false);


				Debug.Log("MODIFIED EVENT: "+keyword+" : "+svalues);

			}
		}
	}


	void validateParams()
	{
		if (_parameters.Count != parameters.Count)
		{
			// Debug.Log("_parameters.Count != parameters.Count");


			_parameters.Clear();
			foreach (string s in parameters)
			{
				_parameters.Add(s);
			}
			return;
		}

		for (int i=0; i<parameters.Count; i++)
		{
			// Debug.Log("parameters [i]:  " + parameters [i]);
			if (parameters [i] != _parameters [i])
			{
				List<string> property = new List<string>(parameters [i].Split(' '));
				string keyword = "";
				string svalue = "";

				//Debug.Log("CHANGED parameters [i]:  " + parameters [i]);

				// remove spaces
				for (int n = 0; n < property.Count; n++)
				{
					if ( keyword == "" && property[n] != "")  
					{
						keyword = property[n];

						// if (n == property.Count) break;

						for (int t = n+1; t < property.Count; t++)
						{
							if ( svalue == "" && property[t] != "")
							{
								svalue = property[t];
								break;
							}
						}

					}
				}

				// Debug.Log("\t \t \t WE GOT:  MODIFIED parameter: "+keyword+" : "+ svalue);
				//  Debug.Log("\t parameter len = " + parameter.Count);
				//            foreach (string item in parameter)   Debug.Log("\t PROPERTY ATOM: " + item);       

				// if incomplete parameter abort
				if (keyword == "" || svalue == "") 
				{
					//Debug.Log("parameterMessage too short:  " + parameters [i]);
					return;
				}

				// else the parameter is valid

				// rewrite parameter without white spaces
				_parameters[i] = parameters[i] = keyword + " " + svalue;

				//Debug.Log("MODIFIED PROPERTY: "+keyword+" : "+svalue);
				sendEvents (parameters, true);
			}
		}
	}


	void sendEvents(List <string> messages, bool setParamFlag)
	{

        if (!_start)
            return;
        
        foreach (string s in messages)
		{
			if (s.Equals("") ) continue;
			

			List<string> items = new List<string>(s.Split(' '));

			List<object> atoms = new List<object>();

            //Debug.LogError(transform.name+":" + s);

			foreach (string value in items)
			{
				int ivalue;
				float fvalue;


                //Debug.LogError("\t  value_" + value + "_");

				if (int.TryParse(value, out ivalue))
				{
					//Debug.Log("ITEM IS AN INTEGER = " + ivalue);
					atoms.Add(ivalue);
				} else if (float.TryParse(value, out fvalue))
				{
					//Debug.Log("ITEM IS A FLOAT = " + fvalue);
					atoms.Add(fvalue);
				} else
				{
					//Debug.Log("ITEM IS A STRING = " + svalue);
					atoms.Add(value);
				}
			}
			if (atoms.Count < 2)
			{
				Debug.LogWarning("SATIEprocess.sendState(): " + transform.name + ":  incomplete message");
			}
			else if (atoms[0].GetType() !=  typeof(string))
			{
				Debug.LogWarning("SATIEprocess.sendState(): " + transform.name + ":  first item in message must be a string");
			}
			else   // message good. Send it now
			{
				if (setParamFlag) atoms.Insert(0, "setParam");
                //Debug.Log("***********  "+atoms);
				SATIEsourceCS.sendEvent(atoms);
			}
		}
	}

	public void setParameter(string keyword, object value)
	{
		string newParam = "";
		string valueStr = value.ToString();

		if (keyword == "" || valueStr == "") {
			Debug.LogWarning ("SATIEprocess.setParameter(): bad keyword or value");
			return;
		}


		//if (value.GetType () == typeof(float))
			


		for (int i = 0; i < parameters.Count; i++) 
		{
			if (parameters [i].Contains (keyword)) 
			{
				parameters [i] = newParam = keyword + " " + valueStr;
			}
		}

		if (newParam == "")  // didn't find the parameter so add it
		{
			newParam = keyword + " " + valueStr;
			parameters.Add ( newParam );
		}
		sendEvents (parameters, true); 
	}

}
