ruleset manage_fleet {
	meta {
		name "manage fleet"
		description << part one of the multiple pico lab >>
		author "Andrew Manwaring"
		logging on
		sharing on
	}
	global{

	}
	rule create_vehicle {
		select when car new_vehicle
		pre {
			attributes = {}
				.put(["Prototype_rids"],"track_trips_part_2;trip_store")
				.put(["name"],event:attr("vehicle_name"))
				;
		}
		{
			event:send({"cid":meta:eci()}, "wrangler", "child_creation")
				with attrs = attributes.klog("attributes: ");
		}
		always {
			log("create child for " + child);
		}
	}
}