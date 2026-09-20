extends Component
class_name Diode

enum TYPE {LED, normal}

@export var forward_voltage: float 				#voltage drop
@export var reverse_breakdown_voltage: float	#peak inverse voltage
@export var diode_type: TYPE					# "led" "normal"
@export var color: Color						# if led else null
@export var max_current: float					# A
