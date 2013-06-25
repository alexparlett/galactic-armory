class Condition
{
	string@ id;
	string@[] tags;
	string@[] conflicts;
	
	Condition(XMLReader@ _xml)
	{
		@id = _xml.getAttributeValue("id");
		
		while(_xml.advance())
		{
			string@ name = _xml.getNodeName();
			if(_xml.getNodeType() == XN_Element && name == "tags")
			{
				if(_xml.advance() && _xml.getNodeType() == XN_Text)
				{
					ParseTags(_xml.getNodeData());
				}
			}
			else if(_xml.getNodeType() == XN_Element && name == "conflict")
			{
				AddConflict(_xml.getAttributeValue("id"));
			}
			else if(_xml.getNodeType() == XN_Element_End && name == "cond")
			{
				break;
			}
		}
	}
	
	bool HasTag(string& _tag)
	{
		for(uint i = 0; i < tags.length(); ++i)
		{
			if(tags[i] == _tag)
			{
				return true;
			}
		}
		return false;
	}
	
	bool HasCondition(string& _conflict)
	{
		for(uint i = 0; i < conflicts.length(); ++i)
		{
			if(conflicts[i] == _conflict)
			{
				return true;
			}
		}		
		return false;
	}
	

	private void ParseTags(string@ _tags)
	{
		uint pos = _tags.find(",");
		if(pos < _tags.length())
		{
			AddTag(_tags.substr(0,pos));
			ParseTags(_tags.substr(pos+1,_tags.length()));
		}
		else
		{
			AddTag(_tags);
		}
	}
	
	private void AddTag(string@ _tag)
	{
		uint n = tags.length();
		tags.resize(n + 1);
		@tags[n] = @_tag;
	}
	
	private void AddConflict(string@ _conflict)
	{
		uint n = conflicts.length();
		conflicts.resize(n + 1);
		@conflicts[n] = @_conflict;
	}
};

class PlanetConditions
{
	Condition@[] posConditions;
	Condition@[] negConditions;	
	
	PlanetConditions()
	{
		XMLReader@ xml = XMLReader("PlanetTypes");
		if(@xml != null)
		{
			while(xml.advance())
			{
				string@ name = xml.getNodeName();
				switch(xml.getNodeType())
				{
					case XN_Element:
						if(name == "cond")
						{
							if(xml.getAttributeValue("type") == "positive")
							{
								uint n = posConditions.length();
								posConditions.resize(n + 1);								
								@posConditions[n] = Condition(xml);
							}
							else
							{
								uint n = negConditions.length();
								negConditions.resize(n + 1);								
								@negConditions[n] = Condition(xml);								
							}
						}
						break;
				}
			}
		}		
	}
	
	bool AddPositiveCondition(Planet@ _pl)
	{
		Condition@ pc = GetRandomPosCondition();
		int attempts = 0;
		while(_pl.hasCondition(pc.id) && attempts < 10)
		{
			@pc = GetRandomPosCondition();
			attempts++;
		}
		
		if(attempts >= 10)
		{
			print("Couldn't find suitable positive condition for planet: " + _pl.toObject().getName());
			return false;
		}
		
		bool suitable = true;
		for(uint i = 0; i < pc.conflicts.length(); ++i)
		{
			if(_pl.hasCondition(pc.conflicts[i]))
			{
				suitable = false;
				break;
			}
		}
		
		const PlanetType@ pt = getPlanetType(getPlanetTypeID(_pl.getPhysicalType()));
		for(uint i = 0; i < pc.tags.length(); ++i)
		{
			if(!pt.hasTag(pc.tags[i]))
			{
				suitable = false;
				break;
			}
		}
		
		if(suitable)
		{
			_pl.addCondition(pc.id);
			return true;
		}
		
		int retry = 0;
		while(retry < 20 && !AddPositiveCondition(_pl))
		{
			retry++;
		}
		
		if(retry >= 20)
		{
			print("Couldn't find suitable positive condition for planet: " + _pl.toObject().getName());
			return false;
		}
		
		return true;		
	}
	
	bool AddNegativeCondition(Planet@ _pl)
	{
		Condition@ pc = GetRandomNegCondition();
		int attempts = 0;
		while(_pl.hasCondition(pc.id) && attempts < 10)
		{
			@pc = GetRandomNegCondition();
			attempts++;
		}
		
		if(attempts >= 10)
		{
			print("Couldn't find suitable negative condition for planet: " + _pl.toObject().getName());
			return false;
		}		
		
		bool suitable = true;
		for(uint i = 0; i < pc.conflicts.length(); ++i)
		{
			if(_pl.hasCondition(pc.conflicts[i]))
			{
				suitable = false;
				break;
			}
		}
		
		const PlanetType@ pt = getPlanetType(getPlanetTypeID(_pl.getPhysicalType()));
		for(uint i = 0; i < pc.tags.length(); ++i)
		{
			if(!pt.hasTag(pc.tags[i]))
			{
				suitable = false;
				break;
			}
		}
				
		
		if(suitable)
		{
			_pl.addCondition(pc.id);
			return true;
		}
		
		int retry = 0;
		while(retry < 20 && !AddNegativeCondition(_pl))
		{
			retry++;
		}
		
		if(retry >= 20)
		{
			print("Couldn't find suitable negative condition for planet: " + _pl.toObject().getName());
			return false;
		}
		
		return true;
	}
	
	private Condition@ GetRandomPosCondition()
	{
		int index = rand(0,posConditions.length());
		return posConditions[index];
	}	
	
	private Condition@ GetRandomNegCondition()
	{
		int index = rand(0,negConditions.length());
		return negConditions[index];
	}
};