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
using System.Collections;
using System.Collections.Generic;
using System;
using System.IO;
using UnityEngine;



//SATIEsetup.setDopplerFactor (nodeName, s, dopplarEffect);
    
//SATIEsetup.setDistanceFactor (nodeName, s, distanceEffect);


//SATIEsetup.setDirectivityFactor (nodeName, s, incidenceEffect);


//SATIEsetup.setMaxGainClip (nodeName, s, maxGainClipDB);


//SATIEsetup.setConnectionMute (nodeName, listener, mute);


// note: this structure will allow for sources to have multiple connections to multiple listeners
// HOWEVER, this implementation is incomplete, due to the work involved to complete it.
// thus, it is assumed elsewhere in the code, that all sources are connected a unique listener;


public class SATIEconnection {
    public float doppler = 100f;
    public float distance = 100f;
    public float directivity = 100f;
    public float maxGainClip = 0f;
    public float radius = 0f;
    public float radiusTransitionFactor = 1.5f;
    public SATIElistener listener=null; 
    public float currentspread=-1;
    public float spread = 1;
	public bool updateFlag = false;
}


public class SATIEsource : SATIEnode {


	[Header("Source Settings")]

	public List<SATIElistener> myListeners = new List<SATIElistener>(); 

	//public string listener="*";
    public string group = "default";   
  
    //public bool mute = false;   not used
    //private bool _mutestate;

	[Header("Culling Settings")]
	public bool cullingMute = false;
	public float cullMuteThreshDB = -66f;
	public float cullMuteUpperThreshOffsetDB = 1f;  // Used to calculate highThreshold for debouncing

	private float _cullMuteLowThreshAmp;
	private float _cullMuteHighThreshAmp;

	private bool _cullMute = false;   // true when distance scaling goes below cullMuteLowThreshDB, false when above cullMuteHighThreshDB

	[Header("Connection Settings")]

	//  threw out vertical directivity: too complicated to avoid gimble lock.
    public string sourceDirectivity = "omni";
    public float cardioidDirectivityExp = 1;  // used when "cardioid" type of source diffusity is selected
  

    public float sourceFocusPercent = 99f;   // this % value is used in the connection to the listener(s), and determines the "spread" of the source on the listener, 0 = widest (omni), 100 = narrowest 
	private float _sourceFocusPercent;

    public float radius = 0f;
	private float _radius;

    public float radiusTransitionFactor = 1.5f;
    private float _radiusTransitionFactor;


    //private float defaultEffectValue = 100f;  // default connection effect parameters value

    public float dopplarEffect = 100f;
    private float _dopplarEffect;

    public float distanceEffect = 100f;
    private float _distanceEffect;

    public float incidenceEffect = 100f;
    private float _incidenceEffect;


    [Range(-42f, 24f)]
    public float gainTrimDB = 0f;  // adds  N DB  to node's gain BEFORE node's maxGainClipDB is applied in connection
    private float _gainTrimDB;


    [Range(-36f, 0f)]
    public float maxGainClipDB = 0f;
    private float _maxGainClipDB = 0f;




	[Header("Underwater Settings")]

	// implemented for a single listener only
	public bool underWaterProcessing = false;  
	public bool aboveWaterMuting = false;    // set this to true for underwaterOnly sounds

    private bool _aboveWaterState = true;

	[Range(1f, 5000f)]
	public float underWaterHpHz = 800;  // low frequency cutoff when underwater
	private float _underWaterHpHz;

	[Range(-80f, 24)]
	public float underWaterDBdrop = -40;  //  DB drop of an above water sound, when heard when under water
	private float _underWaterDBdrop;

	[Range(0.01f, 300f)]
	public float underWaterLpassEffect = 500;  // low pass  effect % for underWater connection
	private float _underWaterLpassEffect;

	[Range(0.01f, 300f)]
	public float underWaterDistanceEffect = 50;  // distance effect %  for underWater connection
	private float _underWaterDistanceEffect;

	[Range(0.01f, 300f)]
	public float underWaterIncidenceEffect = 50;  // distance effect %  for underWater connection
	private float _underWaterIncidenceEffect;


    private bool _initialized = false;

    private float SPEED_OF_SOUND = 0.340f;



    //private bool _initialized = false;



    [HideInInspector]
    public List<SATIEconnection> myConnections = new List<SATIEconnection>();

    delegate float SrcDirFnPtr(float theta);   //holds function for node's H directivity
    SrcDirFnPtr srcDirFnPtr;
	


	void refresh()
	{
		_cullMuteLowThreshAmp = Mathf.Pow(10f, cullMuteThreshDB/20f);

		_cullMuteHighThreshAmp = Mathf.Pow(10f, ( cullMuteThreshDB + cullMuteUpperThreshOffsetDB) / 20f);


		if ( !cullingMute && _cullMute)
		{
			setNodeActive (nodeName, true);
			_cullMute = false;
		}

	}


	public override void OnValidate()
	{

     
         base.OnValidate();
	
 

        if (!_initialized)
            return;
        	
		refresh();
  
        if (_sourceFocusPercent != sourceFocusPercent)
		{
			_sourceFocusPercent = sourceFocusPercent = Mathf.Clamp(sourceFocusPercent, 0f, 100f); 
			updateConnectionParams();
		}
		if (_radius != radius)
		{
			_radius = radius; 
			updateConnectionParams();
		}
 
        if (_radiusTransitionFactor != radiusTransitionFactor)
        {
            _radiusTransitionFactor = radiusTransitionFactor; 
            updateConnectionParams();
        }
        if (_dopplarEffect != dopplarEffect)
        {
            _dopplarEffect = dopplarEffect; 
            updateConnectionParams();
        }
        if (_distanceEffect != distanceEffect)
        {
            _distanceEffect = distanceEffect; 
            updateConnectionParams();
        }
        if (_incidenceEffect != incidenceEffect)
        {
            _incidenceEffect = incidenceEffect; 
            updateConnectionParams();
        }

        if (_maxGainClipDB != maxGainClipDB)
        {
            _maxGainClipDB = maxGainClipDB; 
            updateConnectionParams();
        }
        if (_gainTrimDB != gainTrimDB)
        {
            _gainTrimDB = gainTrimDB; 
            updateConnection();
        }
		if (_underWaterDBdrop != underWaterDBdrop)
		{
			_underWaterDBdrop = underWaterDBdrop; 
            updateConnection();
		}
		if (_underWaterLpassEffect != underWaterLpassEffect)
		{
			_underWaterLpassEffect = underWaterLpassEffect; 
            updateConnection();
		}
		if (_underWaterDistanceEffect != underWaterDistanceEffect)
		{
			_underWaterDistanceEffect = underWaterDistanceEffect; 
            updateConnection();
		}
		if (_underWaterIncidenceEffect != underWaterIncidenceEffect)
		{
			_underWaterIncidenceEffect = underWaterIncidenceEffect; 
            updateConnection();
		}
		if (_underWaterHpHz != underWaterHpHz) 
		{
			_underWaterHpHz = underWaterHpHz;
            updateConnection();
		}
	}

    public void setGainTrimDB(float trimDB)
    {
        gainTrimDB = trimDB;

        if (_gainTrimDB != gainTrimDB)
        {
            _gainTrimDB = gainTrimDB; 
            updateConnection();
        }
    }

   public override void Start()
    {
 
        _initialized = true;

        //bool result = false;
		nodeType = "source";

		if (gameObject.tag == null) group = "default";
		else if (gameObject.tag != "Untagged")  
			group = gameObject.tag;
        else group = "default";

		//Debug.Log("************ source: " + nodeName + "  group_______: " + group);

        initNode();  // must be called before parent's "Start()"
        base.Start();
       
		//Debug.Log("************\tsource: " + nodeName + "  group_______: " + group);

		_cullMuteLowThreshAmp = Mathf.Pow(10f, cullMuteThreshDB/20f);

		_cullMuteHighThreshAmp = Mathf.Pow(10f, ( cullMuteThreshDB + cullMuteUpperThreshOffsetDB) / 20f);

        _sourceFocusPercent = sourceFocusPercent = Mathf.Clamp(sourceFocusPercent, 0f, 100f);

        _radius = radius;

        _radiusTransitionFactor = radiusTransitionFactor;

        _dopplarEffect = dopplarEffect;


        _distanceEffect = distanceEffect;

        _incidenceEffect = incidenceEffect;

        _maxGainClipDB = maxGainClipDB;

        _underWaterHpHz = underWaterHpHz;

        _underWaterIncidenceEffect = underWaterIncidenceEffect; 

        _underWaterDistanceEffect = underWaterDistanceEffect; 

        _underWaterLpassEffect = underWaterLpassEffect; 

        _underWaterDBdrop = underWaterDBdrop; 

        setHorizontalDirectivity(sourceDirectivity);
 
        //Debug.Log("SATIEsetup.setDirectivity " + nodeName + "  htab:" + HorizontalDirectivity + "  vtab:" + VerticalDirectivity);
        //result = SATIEsetup.setDirectivity(nodeName, hDirectivity, vDirectivity);
//        if (result == false)
//            Debug.LogWarning("SATIEsource.start: bad directiviry table name"); 



//        if (radius != 0f)
//        {
//            //SATIEsetup.setRadius(nodeName, radius);
//            //SATIEsetup.setTransitionRadiusFactor(nodeName, radiusTransitionFactor);
//        }


//        if (listener != "")   // any connection parameters to set ?
//        {
//            if (listener != "*")
//            {
//                foreach (Transform obj in listenerInsatances)
//                {
//					string s = obj.name;
//                    if (s.Contains(listener))
//                    {
//                        listener = s;
//                        break;
//                    }
//                 }
//
//            }
          StartCoroutine( connectionInit() );
         //}
     }

	void updateConnectionParams()
	{
		foreach (SATIEconnection conn in myConnections) {
			// note: the current implimentation does not provide for multiple listeners with listener-specific connection params.
			
			//SATIEconnection c = new SATIEconnection (); // Never used warning
			
			conn.doppler = dopplarEffect;
			conn.distance = distanceEffect;
			conn.directivity = incidenceEffect;
			conn.maxGainClip = maxGainClipDB;
			conn.radius = radius;
			conn.radiusTransitionFactor = radiusTransitionFactor;
			conn.spread = sourceFocusPercent * 0.01f; 

		}
        updateConnection();
	}

    private void updateConnection()
    {
        updatePosFlag=true;
        updateRotFlag=true;
    }

    IEnumerator connectionInit() // now that litener(s) have been conection related parameters.
    {
		yield return new WaitForFixedUpdate ();
		//yield return new WaitForSeconds(.05f);

		List<SATIElistener> tempListeners = new List<SATIElistener>(); 

        add2Group(group);  // this can be done now that objects are instantiated

        // now try to create myConnections

        if (listenerInsatances.Count == 0)
        {
            Debug.LogError("SATIEsource.connectionInit: node: " + nodeName + " no listeners found in environment, can't connect");
        } 
        else  // we are in business, make connection(s)
        {

            // check to make sure the listeners in myListeners are good, if not, remove them from myListeners list
            foreach (SATIElistener listener in myListeners)
            {
				if (listener != null)
                {
					if (listenerInsatances.Contains(listener))
                    {
						tempListeners.Add(listener);
                    } else
                    {
						Debug.LogError("SATIEsource.connectionInit:  myListeners's gameObj: " + listener.name + " INVALID LISTENER");
                    }
               } 
            }

            if (tempListeners.Count != myListeners.Count)
            {
                myListeners.Clear();
				foreach (SATIElistener listener in tempListeners)
					myListeners.Add(listener);
                tempListeners.Clear();
            }

            // despite all, no valid listener objects were found in myListeners, so automatically put all listeners in myListeners
            if (myListeners.Count == 0)
            {
				foreach (SATIElistener listener in listenerInsatances)
					myListeners.Add(listener);
            }

            // set up parameters for connection(s)
			foreach (SATIElistener listener in myListeners)
            {
               // note: the current implimentation does not provide for multiple listeners with listener-specific connection params.

                SATIEconnection conn = new SATIEconnection();
                
				conn.listener = listener;
				conn.doppler = dopplarEffect;
				conn.distance = distanceEffect;
				conn.directivity = incidenceEffect;
				conn.maxGainClip = maxGainClipDB;
				conn.radius = radius;
				conn.radiusTransitionFactor = radiusTransitionFactor;
				conn.spread = sourceFocusPercent * 0.01f; 

                
				myConnections.Add(conn);

                //   /spatosc/core connect srcNode listenerNode
                string path = "/spatosc/core";
                List<object> items = new List<object>();
                
                
                items.Add("connect");
                items.Add(nodeName);
				items.Add(listener.name);
                
                
                SATIEsetup.OSCtx(path, items);
                items.Clear();
            }
        }
	}


	public void add2Group(string groupName)
	{
		//Debug.Log("add2Group:  add  " + transform.name + "  to sourceNode: " + groupName);

		foreach (SATIEnode obj in groupInsatances)  // check to see if source has same tag as any groups
		{
			if (obj.gameObject.tag == groupName)
			{
				obj.SendMessage("addMember", this);  // add to group
			    this.group = obj.gameObject.tag;
				//Debug.Log("sSAME TAG : " + gameObject.tag + " FOUND FOR GROUP OBJ: " + obj.name + " and  source: " + gameObject.name);

				break;   // source and only be a member of one group
			}
		}
		//GameObject groupObj = GameObject.FindWithTag (gameObject.tag);
 	}

	// best called in the context of lateUpdate() since flags can be set to true during FixedUpdate() or Uptade()
 	public void evalConnections()
    {
		if (!nodeEnabled) return;

		foreach ( SATIEconnection conn in myConnections)
		{
            if (conn.listener.updatePosFlag || conn.listener.updateRotFlag || updatePosFlag || updateRotFlag )
			{
				computeConnection(conn);

				updatePosFlag = updateRotFlag = false;
			}
		}
    }

	

    
    // ***************************************  start of connection stuff ****************

    void computeConnection(SATIEconnection conn)
    {



        string path;
        List<object> items = new List<object>();
        
		SATIElistener listener = conn.listener;


        Transform source = transform;
 
		float newSpread;

		float vdelMs_, distFq_, gainDB_;
        float myRadius = conn.radius;

        float azimuth, elevation,distance;
//		float dist2Dxz;  // Never used warning

        Vector3 listenerAED = new Vector3();            

        // get distance and angles of source relative to listener
        listenerAED = getAedFromSink(source.position, listener);
        azimuth = listenerAED.x;
        elevation = listenerAED.y;
        distance = listenerAED.z;
        //dist2Dxz = getDist2Dxz(source,listener);   // not used


        //For the gain and vdel calculation, we want the distance to the radius:
		float dist2Radius = distance - myRadius;
		float scaledDistance = getScaledDist(listener,dist2Radius);
		float distanceScaler =  1.0f / (1.0f + scaledDistance);


		// first test for culling
		if (cullingMute) 
		{			
			if (_cullMute) 
			{
				if (distanceScaler < _cullMuteHighThreshAmp) 
				{
					return; // node is still too far to take action
				} else 
				{
					setNodeActive (nodeName, true);
					_cullMute = false;
					//Debug.Log ("DISABLING CULLING MUTING ");

				}
			}
		}
		// ! _cullMute testing is done at the end of this function


		if (aboveWaterMuting)
		{
			if (!listener.submergedFlag )   // we are above water
			{
				if (_aboveWaterState == true)
					return;   
			}
			else // we are below water
			{
				_aboveWaterState = false;
			}
		}

				//  set  cutoff filter to eliminate low frequencies when under water
        if (listener.submergedFlag  && underWaterProcessing ) {
			if (_underWaterHpHz != underWaterHpHz) {
				_underWaterHpHz = underWaterHpHz;
				path = "/spatosc/core/connection/" + source.name + "->" + listener.name + "/hpHz";
				items.Add (_underWaterHpHz);             
				SATIEsetup.OSCtx (path, items);   // send spread message via OSC
				items.Clear ();
				//Debug.Log("_underWaterHpHz = " + _underWaterHpHz);
			}
		} else 
		{
			if (_underWaterHpHz == underWaterHpHz) {
				_underWaterHpHz = 1f;		// reset the cutoff filter to normal
				path = "/spatosc/core/connection/" + source.name + "->" + listener.name + "/hpHz";
				items.Add (_underWaterHpHz);             
				SATIEsetup.OSCtx (path, items);   // send spread message via OSC
				items.Clear ();
				//Debug.Log("_underWaterHpHz = " + _underWaterHpHz);
			}
		}


		// handle spread
		path = "/spatosc/core/connection/" + source.name + "->"+listener.name+"/spread";

		// Using radius effect?  then check to see if we are within the radius transition distance; if so, reduce the localization effect for panning: via spread
		if ( myRadius > 0f )    
        {
			// have not yet debugged this case when underWaterProcessing is used

 
			float radiusTransitionDistance = myRadius * conn.radiusTransitionFactor;
            

			if (listener.submergedFlag && underWaterProcessing)
				newSpread = underWaterIncidenceEffect * .01f ;   // diminish incidence underwater: multiply the spread by some percentage 
			else 
				newSpread = conn.directivity * .01f * getSpreadIndex(distance, myRadius, radiusTransitionDistance, conn.spread);


            if ( newSpread != conn.currentspread )   // changed ?
            {
                // path = "/spatosc/core/connection/" + source.name + "->"+listener.name+"/spread";   REDUNDANT LINE COMMENTED OUT
                conn.currentspread = newSpread;

                items.Add(newSpread);             
                SATIEsetup.OSCtx(path, items);   // send spread message via OSC
                items.Clear();

				// SATIEsetup.OSCdebug("/debug/getSpreadIndex", getSpreadIndex(distance, myRadius, radiusTransitionDistance, conn.spread));

            }
        }
		else // no radus effect, so just make sure any new spread changes are handled
		{
			if (listener.submergedFlag && underWaterProcessing)
				newSpread = underWaterIncidenceEffect * .01f ;   // diminish incidence underwater: multiply the spread by some percentage 
			else 
				newSpread = conn.spread; 

			if (conn.currentspread != newSpread)
			{
				conn.currentspread = newSpread;
				items.Add(newSpread);             
				SATIEsetup.OSCtx(path, items);   // send spread message via OSC
				items.Clear();
				//SATIEsetup.OSCdebug("/debug/getSpreadIndex", conn.spread);
			}
		}

        
	
        if (dist2Radius>0f)
        {
            // now from distance, compute gain, lowPassCutoff-fq and variable delay:
            float srcDirectivityScaler;

//			float distanceEffect = conn.distance; // Never used warning
//			float lowPassEffect; // Never used warning
//			float directivityEffect = conn.directivity; // Never used warning
            
			vdelMs_ = getVariableDelay(dist2Radius, conn.doppler);   // calculate this independently of underwater status

//			if (listener.submergedFlag && underWaterProcessing)
//			{
//				scaledDistance = Mathf.Pow(dist2Radius, underWaterDistanceEffect * 0.01f ); // calculate distanceFactor for underwater
//			}
//			else 
//				scaledDistance = Mathf.Pow(dist2Radius, distanceEffect * 0.01f); // calculate distanceFactor (effect) param
  
            distFq_ = getDistFq(scaledDistance);  // using distance after distanceFactor applied          

            //distanceScaler = 1.0f / (1.0f + scaledDistance);

			srcDirectivityScaler = calcSrcDirectivity(conn);  

            if (debug) Debug.DrawRay (source.position, (source.forward * 50f * srcDirectivityScaler), Color.green, 2f); 

            // obtain connection energy using distance * sourceDirectivity (based on incidence to listener)

			if (listener.submergedFlag && underWaterProcessing)
				gainDB_ = getGainDB(distanceScaler, srcDirectivityScaler, (underWaterIncidenceEffect * 0.01f), conn.maxGainClip);
			else
				gainDB_ = getGainDB(distanceScaler, srcDirectivityScaler, conn.directivity, conn.maxGainClip);


            if (listener.submergedFlag  && underWaterProcessing )
			{
				//distFq_ = distFq_ * underWaterLpassEffect  * 0.01f;
				//Debug.Log("distFq_ = " + distFq_);

				// distFq_ =  distFq_ *  (100f / underWaterLpassEffect); // calculate distanceFactor (effect) param

				distFq_ =  Mathf.Pow (distFq_, (100 / underWaterLpassEffect)); // calculate distanceFactor (effect) param
				distFq_ = Mathf.Clamp(distFq_, 100, 22050f); 

				// sounds not supposed to be heard underwater can be greatly attenuated
				if(underWaterProcessing)
				{
					gainDB_ = gainDB_ + underWaterDBdrop; // calculate distanceFactor (effect) param
					// if ( gainDB_ > conn.maxGainClip )  gainDB_ =   conn.maxGainClip;
				}
			}
		}
		else   // very close to sound node, no attenuation effect
        {
			vdelMs_ = 0.0f;	
			gainDB_ = conn.maxGainClip ;

            // WAS if (listener.submergedFlag) 
            if (listener.submergedFlag  && underWaterProcessing )
			{
				distFq_ =  Mathf.Pow (22050f, (100 / underWaterLpassEffect)); // calculate distanceFactor (effect) param
				distFq_ = Mathf.Clamp(distFq_, 100, 22050f); 

                // was if (!underWaterProcessing)
				//      gainDB_ = gainDB_  + underWaterDBdrop;
					gainDB_ = gainDB_  + underWaterDBdrop;
			}
			else
			{
				distFq_ = 22050f;
			}
		}
        // /spatosc/core/connection/sourceNode->listenerNode/update azimuthRADIANS elevationRADIANS gainDB delayMS  lpHZ 
        // Debug.Log("  AZI: "+ azimuth*Mathf.Rad2Deg+"  Elev: "+elevation*Mathf.Rad2Deg); 

        path = "/spatosc/core/connection/" + source.name + "->"+listener.name+"/update";



        if (!listener.submergedFlag && aboveWaterMuting)
        {
            //Debug.Log("ABOVE WATER ATTENUATION");
            gainDB_ = -90f;
            _aboveWaterState = true;
        }

        items.Add(azimuth);
        items.Add(elevation);
        items.Add(gainDB_);
        items.Add(vdelMs_);
        items.Add(distFq_);
        items.Add (distance);

		SATIEsetup.OSCtx(path, items);   // send OSC connection update

		items.Clear();


        //Debug.Log("CONNECTION DISTANCE FROM LISTENER: " + distance);

		// node has entered into culling muting,  set state accordingly
		if (cullingMute) 
		{
			if (!_cullMute && (distanceScaler < _cullMuteLowThreshAmp)) 
			{
				setNodeActive (nodeName, false);
				_cullMute = true;
				//Debug.Log ("ENABLING CULLING MUTING ");
			}
		}
     }

    // called with a position,  using the node's connection params,   connection update parameters are generated and returned.  
    // Typically called by a particle gen. script, that is a parent of this srcNode
    // returns list of azi, elev, gain, delayMs, lpassFq, hpassFq , distance
    // STILL NEED TO FULLY IMPLEMENT  UNDERWATER STUFFF


    // NOTES TO SELF ABOUT THIS
    //  SPREAD seems to be mishandled... an additional connection param should be added for that



    public List <float>  getParticleConnParams(Vector3 particleXYZ)
    {
        List<float> connParams = new List<float>();

        List<object> items = new List<object>();

        Transform source = transform;
        SATIEconnection conn = null;
        SATIElistener listener = null;

        float HpHz = 1f;  // using temp variable here

        if (!nodeEnabled)
            return connParams;

        //Debug.Log("getParticleConnParams: CONNECTION COUNT: "+ myConnections.Count);

        foreach ( SATIEconnection connection in myConnections)
        {
            listener = connection.listener;
            conn = connection;

            if (conn != null && listener != null) break;
        }

        if (listener == null )
        {
            Debug.LogWarning("SATIEsource.getParticleConnParams(): no listener, can't processes"); 
            return connParams;
        }

        if (conn == null )
        {
            Debug.LogWarning("SATIEsource.getParticleConnParams(): no connection, can't processes"); 
            return connParams;
        }

        float newSpread;

        float vdelMs_, distFq_, gainDB_;

        float azimuth, elevation, distance;

        Vector3 listenerAED = new Vector3();            

        // get distance and angles of source relative to listener
        listenerAED = getAedFromSink(particleXYZ, listener);
        azimuth = listenerAED.x;
        elevation = listenerAED.y;
        distance = listenerAED.z;

        //For the gain and vdel calculation, we want the distance to the radius:
        //float dist2Radius = distance - myRadius;      NO radius calculation--- RADIUS FEATURE DISABLED FOR NOW


       //  set  cutoff filter to eliminate low frequencies when under water
        if (listener.submergedFlag)
        {
            if (_underWaterHpHz != underWaterHpHz)
            {
                _underWaterHpHz = underWaterHpHz;

            }
        } else
        {
            if (_underWaterHpHz == underWaterHpHz)
            {
                _underWaterHpHz = 1f;       // reset the cutoff filter to normal

            }
        }
  

        if (listener.submergedFlag && underWaterProcessing)
            newSpread = underWaterIncidenceEffect * .01f ;   // diminish incidence underwater: multiply the spread by some percentage 
        else 
            newSpread = conn.spread; 

        if (conn.currentspread != newSpread)
        {
            string path = "/spatosc/core/connection/" + source.name + "->"+listener.name+"/spread";

            conn.currentspread = newSpread;
            items.Add(newSpread);             
            SATIEsetup.OSCtx(path, items);   // send spread message via OSC
            items.Clear();
            //SATIEsetup.OSCdebug("/debug/getSpreadIndex", conn.spread);
        }



        float dist2Radius = distance;  // RADIUS PROCESSING DISABLED..
        if (dist2Radius > 0f)     // SO THIS IS ALWAYS CALLED FOR ALL DISTANCES > ZERO    
        {
            // now from distance, compute gain, lowPassCutoff-fq and variable delay:
            float distanceScaler;
            float scaledDistance; 
            float srcDirectivityScaler;

            float distanceEffect = conn.distance;
//			float lowPassEffect; // Never used warning
//			float directivityEffect = conn.directivity; // Never used warning

            vdelMs_ = getVariableDelay(dist2Radius, conn.doppler);   // calculate this independently of underwater status

            if (listener.submergedFlag && underWaterProcessing)
            {
                scaledDistance = Mathf.Pow(dist2Radius, underWaterDistanceEffect * 0.01f); // calculate distanceFactor for underwater
            } else
                scaledDistance = Mathf.Pow(dist2Radius, distanceEffect * 0.01f); // calculate distanceFactor (effect) param

            distFq_ = getDistFq(scaledDistance);  // using distance after distanceFactor applied          

            distanceScaler = 1.0f / (1.0f + scaledDistance);

            srcDirectivityScaler = calcSrcDirectivity(conn);  

            if (debug)
                Debug.DrawRay(particleXYZ, (Vector3.forward * 50f * srcDirectivityScaler), Color.green, 2f); 

            // obtain connection energy using distance * sourceDirectivity (based on incidence to listener)

            if (listener.submergedFlag && underWaterProcessing)
                gainDB_ = getGainDB(distanceScaler, srcDirectivityScaler, (underWaterIncidenceEffect * 0.01f), conn.maxGainClip);
            else
                gainDB_ = getGainDB(distanceScaler, srcDirectivityScaler, conn.directivity, conn.maxGainClip);



            if (listener.submergedFlag  && underWaterProcessing )
            {
                //distFq_ = distFq_ * underWaterLpassEffect  * 0.01f;
                //Debug.Log("distFq_ = " + distFq_);

                // distFq_ =  distFq_ *  (100f / underWaterLpassEffect); // calculate distanceFactor (effect) param

                distFq_ =  Mathf.Pow (distFq_, (100 / underWaterLpassEffect)); // calculate distanceFactor (effect) param
                distFq_ = Mathf.Clamp(distFq_, 100, 22050f); 

                // sounds not supposed to be heard underwater can be greatly attenuated
                if(underWaterProcessing)
                {
                    gainDB_ = gainDB_ + underWaterDBdrop; // calculate distanceFactor (effect) param
                    // if ( gainDB_ > conn.maxGainClip )  gainDB_ =   conn.maxGainClip;
                }
            }
        }
        else   // IGNORE:  very close to sound node
        {
            vdelMs_ = 0.0f; 
            gainDB_ = conn.maxGainClip ;

            // WAS if (listener.submergedFlag) 
            if (listener.submergedFlag  && underWaterProcessing )
            {
                distFq_ =  Mathf.Pow (22050f, (100 / underWaterLpassEffect)); // calculate distanceFactor (effect) param
                distFq_ = Mathf.Clamp(distFq_, 100, 22050f); 

                // was if (!underWaterProcessing)
                //      gainDB_ = gainDB_  + underWaterDBdrop;
                gainDB_ = gainDB_  + underWaterDBdrop;
            }
            else
            {
                distFq_ = 22050f;
            }
        }
 
        if (!listener.submergedFlag && aboveWaterMuting)
        {
            //Debug.Log("ABOVE WATER ATTENUATION");
            gainDB_ = -90f;    // we do not set _aboveWaterMuting since it is not used to trigger a return() from this funciton
        }

        if ( ! listener.submergedFlag && aboveWaterMuting ) gainDB_ = -99;

        HpHz = (listener.submergedFlag && underWaterProcessing) ? underWaterHpHz : 1f;

        connParams.Add(azimuth);        // 0
        connParams.Add(elevation);      // 1
        connParams.Add(gainDB_);        // 2
        connParams.Add(vdelMs_);        // 3
        connParams.Add(distFq_);        //4
        connParams.Add(HpHz); //5     using a temp variable in debugging this
        connParams.Add(distance);      // 6

        //Debug.Log(transform.name+": getParticleConnParams: UNDERWATER FLAG: "+ underWaterProcessing+" :  hz= "+HpHz);

        return (connParams);
    }

    float getScaledDist (SATIElistener listener, float dist2Radius)
	{
//		float scaledDistance; // Never used warning

		if (listener.submergedFlag && underWaterProcessing)
			return Mathf.Pow(dist2Radius, underWaterDistanceEffect * 0.01f); // calculate distanceFactor for underwater
		else
			return Mathf.Pow(dist2Radius, distanceEffect * 0.01f); // calculate distanceFactor (effect) param
	}


    // returns the projected distance on XZ 
    float getDist2Dxz(Transform src, SATIElistener snk)
    {
        Vector2 srcVec = new Vector2(src.position.x, src.position.z);
        Vector2 snkVec = new Vector2(snk.transform.position.x, snk.transform.position.z);

        return( Vector2.Distance(srcVec,snkVec) );
    }




    public Vector3 getAedFromSink(Vector3 src, SATIElistener snk)
	{
		Vector3 connVec = src - snk.transform.position;
		
		// Rotate connVec by the negative of the rotation described by the snk's
		// orientation. To do this, just flip the sign of the quat.w:
		
		//Quaternion negRot = snk.rotation * Quaternion.Euler(0, 0, 0);
		Quaternion negRot = snk.transform.rotation;
		negRot.w *= -1f;
		Vector3 rotConnVec = negRot * connVec;
		
		Vector3 aed = cartesianToSpherical(rotConnVec);


		//Debug.DrawRay (snk.position, rotConnVec); 
		return new Vector3 (aed.x * ((SATIEsetup.invertAzi) ? -1f:1f), aed.y, aed.z);   // invert x to work with UNITY
	}


    // does dot product to see how much source is pointing at sink
	float getSrcIncidenceOnSnk(Transform src, SATIElistener snk)
    {
        Vector3 connVec = Vector3.Normalize(snk.transform.position - src.position);  

        Vector3 srvVec = Vector3.Normalize(src.TransformDirection(Vector3.forward));

        float incidence = Vector3.Dot(srvVec , connVec);

        return incidence;        
    }


    Vector3 cartesianToSpherical(Vector3 v)
    {
        // swapped Y and Z for use with UNITY

        // http://en.wikipedia.org/wiki/Spherical_coordinate_system
        // but modified, since ground ref is the XY plane
        
        float azim, elev, dist;

        dist = Vector3.Magnitude(v);

        //azim = Mathf.Atan2(v.y,v.x) - Mathf.PI/2; original

        azim = Mathf.Atan2(v.z,v.x) - Mathf.PI/2;

        // put in range of [-pi,pi]
        if (azim > Mathf.PI)
            azim -= 2f * Mathf.PI;
        else if (azim < -Mathf.PI)
            azim += 2f * Mathf.PI;
        
        if (dist > 0.000001f)
            // elev = Mathf.PI/2f - Mathf.Acos(v.z / dist);  original
            elev = Mathf.PI/2f - Mathf.Acos(v.y / dist);
        else
            elev = 0.0f;

        return new Vector3(azim, elev, dist);    // elevation inverted for Unity 
    }


    float getDistFq(float distance)
    {
        // calculate a low-pass cutoff freq. to model air absorption of high frequencies over the distance
        float hz;
        float ms;
        
		distance = (distance > 1000f) ? 1000f : distance;  // clip distance to 1000m

        
        ms = distance * (1.0f / SPEED_OF_SOUND); // convert to milliseconds
        hz = (1f - (ms * 0.00034002f));
					hz= 100f + (hz*hz*19900f);
        return hz;
    }
    
    float getVariableDelay(float distance, float dopplerFactor)
    {
        return Mathf.Pow(distance * (1.0f / SPEED_OF_SOUND), dopplerFactor * 0.01f);
    }
    
    float getGainDB(float distanceScaler, float directivity, float directivityFactor, float gainClip)
    {
        float gainDB;
        
        float directivityScaler = Mathf.Pow(directivity, directivityFactor * 0.01f);
        gainDB = gainTrimDB + 20.0f * Mathf.Log10(distanceScaler * directivityScaler); 
        return ( Mathf.Clamp(gainDB, -9999f, gainClip) );
    }
    
    // returns value ranging from 0 to 1, corresponding to  position within transitionRadius
    // 0: distance <= radius
    // 1: distance <= radiusTransitionDistance
    // or inBetween
    float getSpreadIndex(float distance, float radius, float radiusTransitionDistance, float sourceSpread)
    {
        
        
        if (distance <= radius) return (0f);  // return spread of zero,  i.e. cos to the zeroth power = 1 - no panning effect

  
        if (distance >= radiusTransitionDistance)
        {
            return (sourceSpread);  // not within the transition radius, so set spread to "normal"

        }
        // else we are inbetween radius and radiusTransition limit, so calculate spread using scaled incidenceFactor_
        
        return ( sourceSpread * (distance- radius) / (radiusTransitionDistance - radius) );   
    }

    float  calcSrcDirectivity(SATIEconnection conn)
    {

        Transform src = transform;
        SATIElistener snk = conn.listener;

        float distance = Vector3.Distance( src.position, snk.transform.position ); 

        float incidence = getSrcIncidenceOnSnk(src, snk);
        float radiusClip;

   
        if(radius < 0f)
            radiusClip = 0f;
        else
            radiusClip = radius;

        // float srcIncidenceScaler = srcDirFnPtr(azimut) * vDirFnPtr(elevation);
        // not using spatOSC's two incidence tables,  since its too complicated to avoid gimble lock

        // SATIEsetup.OSCdebug("/debug/incidence", incidence);

        float theata = .5f *(2 - (incidence + 1f)) * Mathf.PI;

        //SATIEsetup.OSCdebug("/debug/theata", theata * Mathf.Rad2Deg);

        float srcIncidenceScaler = srcDirFnPtr(theata);

         //SATIEsetup.OSCdebug("/debug/srcIncidenceScaler", srcIncidenceScaler);

        float radiusScaler = calcFactorFromDirectivityRadius( distance, radiusClip, conn.radiusTransitionFactor);

        srcIncidenceScaler = srcIncidenceScaler*radiusScaler + (1.0f-radiusScaler);

        return srcIncidenceScaler;
    }

    
    float calcFactorFromDirectivityRadius(float dist, float radius, float radiusTransitionFactor)
    {
        if(dist <= radius)
            return 0.0f;
        
        if(dist >= radius*radiusTransitionFactor)
            return 1.0f;
        
        float radiusScaler = (dist - radius) / (radius * (radiusTransitionFactor-1.0f));
        
        return radiusScaler;
    }


    //  functions pointed to by srcDirFnPtr to calculate directivities

    float getOmni(float theata)
    {
        return (1f);
    }


    float getCardoid(float theata)
    {
        return Mathf.Pow(.5f * (1f + Mathf.Cos(theata)), cardioidDirectivityExp);
    }

    float getHemisphere(float theata) // not implemented yet
    {
        return (1f);
    }

    float getCone(float theata)   // not implemented yet
    {
        return (1f);
//        double cone_width_scaler = 1./8.;  // corresponding to PI/8 == 22.5 degrees * 2 due table symmetry,  == PI/4 == 45 degrees
//        double cone_width = size*cone_width_scaler;

    }

// ***************************************  end of connection stuff ****************


//    public override void setUri(string uriString)
//    {
//        if (!_initialized)
//            return;
//        
//        base.setUri(uriString);
//    }
//


    public override void  setNodeActive(string nodeName, bool nodeEnabled)
    {
        base.setNodeActive(nodeName, nodeEnabled);
        //SATIElistener.UpdateConnection += UpdateConnection;  // subscribe to SATIElistener class
		if (!nodeEnabled) updatePosFlag = updateRotFlag = false;
    }

    public override  void deleteNode(string nodeName)
    {
        base.deleteNode(nodeName);
        //SATIElistener.UpdateConnection -= UpdateConnection;  // unsubscribe to SATIElistener class
        myConnections.Clear();
        myListeners.Clear();

    }




    public override void Update()
    {
        base.Update();

//		if (Input.GetKeyDown("e"))
//		{
//
//			float pitch = UnityEngine.Random.Range(40f, 80f);
//			String pstr = pitch.ToString() + ", 1.0";
//
//			Debug.Log(pstr);
//
//
//			//SATIEsetup.sendNodeEvent(nodeName, "note", pstr);
//			//SATIEsetup.sendNodeEvent(nodeName, "t_gate", "1.0" );
//			//Debug.Log("source:Update  sending t_gate event");
//		}
    }


    public override void FixedUpdate()
    {
		base.FixedUpdate();

    }

	public override void LateUpdate()
	{
		base.LateUpdate();
				
	}


    void setHorizontalDirectivity(string tabName)
    {
        switch (tabName)
        {
            case "cardioid":
                srcDirFnPtr = getCardoid;    // sets srcDirFnPtr to point to getCardoid()
                Debug.Log("SETTING CARDOID");
                return;
            case "hemisphere":          // not implemented
                srcDirFnPtr = getHemisphere;
                return;
            case "cone":        // not implemented
                srcDirFnPtr = getCone;
                return;
        }
        // else
        sourceDirectivity = "omni";
        srcDirFnPtr = getOmni;
        //Debug.Log("SETTING OMNI");
    }
 }
