extends Node
class_name dialogs

# Ordered list of event names for this location. The dialog runner plays them in
# this order, skipping any whose prerequisites are not yet met.
var event_priority = [] #for each bldg or loc, which event takes priority takes priority

# Events that have been fully played through for this location.
var completed_events = []

# Returns the name of the first event in event_priority whose prerequisites are
# all met and which has not been completed yet. Returns "" if none is available.
func get_next_runnable_event() -> String:
	for event_name in event_priority:
		if event_name in completed_events:
			continue
		var event = get_event(event_name)
		if event == null:
			continue
		# First item in the event list is the list of prerequisite event names.
		var prerequisites = event[0] if event.size() > 0 else []
		var all_met = true
		for prereq in prerequisites:
			if prereq not in completed_events:
				all_met = false
				break
		if all_met:
			return event_name
	return ""

# Marks an event as completed so it won't be offered again.
func mark_event_completed(event_name: String):
	if event_name not in completed_events:
		completed_events.append(event_name)

# Looks up an event by name on this location script. Substructures define their
# events as variables (e.g. var first_meeting = [...]). Override if you store
# events differently.
func get_event(event_name: String) -> Variant:
	if has_method(event_name):
		# Stored as a function returning the event list.
		return call(event_name)
	# Stored as a member variable. Check the property list so we don't error on
	# missing names.
	for prop in get_property_list():
		if prop.name == event_name:
			return get(event_name)
	return null
