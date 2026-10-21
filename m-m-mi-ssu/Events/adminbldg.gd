extends dialogs

var locname = "adminbldg"
#each dialog is formated in a way such as its a list of lists
#first item in the list is REQUIRED prerequisite events, if its not met, event cant trigger and focus on the next available triggerable event
#then followed by a list of until it terminates
#index, speaker, in position(which speaker are they), (dialog), emotion, trust_gain, next_dialog_index, audiofilepath, then if there are options ignore next dialog index even if it has a value, instead ["option1_text", trust_gain, next_dialog_index, "option2_text", trust_gain, next_dialog_index]
var first_meeting = [
	[], #means no prerequesite event 
	[1, "Nicoe", 1, "Hello", "Neutral", 0 , 2]
]

var nicoe_2 = [
	["first_meeting"], #requires first meeting to be completed first
	[1, "Nicoe", 1, "Hello again", "Neutral", 0 , 2]
]

func _ready():
	event_priority = ["first_meeting", "nicoe_2"]
