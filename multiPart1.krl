ruleset manage_fleet {
	meta {
		name "manage fleet"
		description << part one of the multiple pico lab >>
		author "Andrew Manwaring"
		logging on
		sharing on
		provides vehicles
		provides subscriptions
		provides fleet_trips
		provides fleet_trips_gather
		use module b507199x5 alias wranglerOS
	}
	global{
		vehicles = function() {
			results = wranglerOS:children();
			children = results{"children"};
			children
		};

		subscriptions = function() {
			results = wranglerOS:subscriptions();
			subscriptions = results{"subscriptions"};
			list = subscriptions{"subscribed"};
			list
		};

		fleet_trips = function() {
			all_trips = vehicles().map(function(vehicle) {
				cloud_url = "https://cs.kobj.net/sky/cloud/";
				mod = "b507764x5.prod";
				func = "trips";
				response = http:get("#{cloud_url}#{mod}/#{func}", (params || {}).put(["_eci"], vehicle[0]));

				status = response{"status_code"};

				response{"content"}.decode();
			});
			all_trips
		}

		fleet_trips_gather = function() {
			trips = ent:reports;
			trips
		}

		num_cars_in_report = function(cid) {
			report = ent:reports{[cid]};
			trips.length();
		}
	}
	rule create_vehicle {
		select when car new_vehicle
		pre {
			name = event:attr("vehicle_name");
			attributes = {}
				.put(["Prototype_rids"],"b507764x4.prod;b507764x8.prod;b507764x7.prod") //track_trips_part_2;trip_store;subscription_request
				.put(["name"],name)
				.put(["parent_eci"], "7AC39FAE-F6A9-11E5-BE21-84E6E71C24E1")
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

	rule autoAccept {
		select when wrangler inbound_pending_subscription_added
		pre {
			attributes = event:attrs().klog("subscription: ");
		}
		{
			noop();
		}
		always {
			raise wrangler event "pending_subscription_approval"
				attributes attributes;
				log("auto accepted subscription.")
		}
	}

	rule delete_vehicle {
		select when car unneeded_vehicle
		pre {
			eci = event:attr("target_eci").klog("Pulled target_eci: ");
			channel_name = event:attr("channel_name").klog("Pulled channel_name: ");
			attributes = {}
				.put(["deletionTarget"],eci)
				.put(["channel_name"],channel_name)
				;
		}
		{
			noop();
		}
		always {
			raise wrangler event "child_deletion"
				attributes attributes.klog("attributes: ");
			raise wrangler event "subscription_cancellation"
				attributes attributes.klog("attributes: ");
		}
	}

	rule report_scatter {
		select when car report_scatter
			foreach subscriptions() setting (subscription)
		pre {
			event_eci = subscription.pick("$..event_eci").klog("Event eci: ");
			cid = random:uuid();
			attr = {}
				.put(["cid"], cid)
				;
		}
		{
			event:send({"cid":event_eci},"explicit","report_requested")
				with attr = attr.klog("attributes: ")
		}
		always {
			log("Sent event to: " + event_eci + " with cid: " + cid + " with attr: " + attr);
		}
	}

	rule report_gather {
		select when car report_gather
		pre {
			cid = event:attr("cid");
			report = event:attr("report");
			num_reported = num_cars_in_report(cid);
		}
		always {
			set ent:reports{[cid]} ent:reports{[cid]}.append(report);
		}
	}
}