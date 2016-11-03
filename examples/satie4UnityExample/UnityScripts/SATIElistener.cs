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

public class SATIElistener : SATIEnode {
    
    //public delegate void SATIEConnection(Transform tr, bool posFlag, bool rotFlag);
	
	[Header("Listener Settings")]

	public bool submergedFlag = false;
	private bool _submergedFlag;

    public override void Start()
    {

        if ( ! this.gameObject.activeInHierarchy)  return;

		nodeType = "listener";

        initNode();  // must be called before parent's "Start()"
        base.Start();
    }

	public override void OnValidate()
	{
		base.OnValidate();


		if (_submergedFlag != submergedFlag)
		{
			_submergedFlag = submergedFlag;
            updatePosFlag = true;
            //setSubmerseStatus();
			// setNodeActive(nodeName, nodeEnabled);
		}

		
	}

//	void setSubmerseStatus()
//	{
//
//		string path;
//		List<object> items = new List<object>();
//		int state = (_submergedFlag) ? 1 : 0;
//		
//		items.Add( state );             
//
//		foreach (SATIEnode src in sourceInsatances) 
//		{
//			path = "/spatosc/core/connection/" + src.name + "->" + name + "/hpHz";   // 
//			//SATIEsetup.OSCtx (path, items);   // send spread message via OSC
//		}
//		items.Clear();
//
//	}




    public override void Update()
    {
        base.Update();
        if (_submergedFlag != submergedFlag)
        {
            _submergedFlag = submergedFlag;

            updatePosFlag = true;
           // setSubmerseStatus();
        }
    }

    public override void FixedUpdate()
    {
        base.FixedUpdate();
    }

	public override void LateUpdate()
	{
		base.LateUpdate();
	}
	
    public override void  setNodeActive(string nodeName, bool nodeEnabled)
    {
        base.setNodeActive(nodeName, nodeEnabled);
    }
    
    public override  void deleteNode(string nodeName)
    {
        base.deleteNode(nodeName);
    }
}
