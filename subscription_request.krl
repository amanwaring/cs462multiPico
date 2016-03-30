ruleset subscription_request {
	meta {
		name "subscription request"
		description << part one of the multiple pico lab, child sending request >>
		author "Andrew Manwaring"
		logging on
		sharing on
		use module  b507199x5 alias wrangler_api
	}
	global{

	}
	rule childToParent {
		select when wrangler init_events
		pre {
			parent_results = wrangler_api:parent();
			parent = parent_results{'parent'};
			parent_eci = parent[0];
			attrs = {}
				.put(["name"], "Family")
				.put(["name_space"], "Andrews_Attempt_To_Copy_Tutorial_Susbscriptions")
				.put(["my_role"], "Child")
				.put(["your_role"], "Parent")
				.put(["target_eci"], parent_eci.klog("target Eci: "))
				.put(["channel_type"], "Pico_Tutorial???")
				.put(["attrs"], "success")
				;
		}
		{
			noop();
		}
		always {
			raise wrangler event "subscription"
				attributes attrs;
		}
	}
	
}