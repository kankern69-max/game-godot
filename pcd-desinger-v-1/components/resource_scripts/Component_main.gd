extends Resource
class_name Component

enum type {resistor, capacitor, inductor, diode, led, transistor, ic, switch, battery, ground, potentiometer, fuse, buzzer, motor}

@export var component_id: String
@export var component_name: String
@export var component_type: type
@export var description: String
@export var footprint: Vector2i
@export var cost: float
@export var atlas_coords: Vector2i
@export var power_rating: float #w
