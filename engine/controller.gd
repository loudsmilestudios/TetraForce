extends Node

const UP: String = "UP"
const DOWN: String = "DOWN"
const LEFT: String = "LEFT"
const RIGHT: String = "RIGHT"

const A: String = "A"
const B: String = "B"
const X: String = "X"
const Y: String = "Y"

const L: String = "L"
const ZL: String = "ZL"
const R: String = "R"
const ZR: String = "ZR"

const START: String = "START"
const SELECT: String = "SELECT"

var default: Dictionary = {
	"schema": "0",
	"input.keys": {
		UP: KEY_UP,
		DOWN: KEY_DOWN,
		LEFT: KEY_LEFT,
		RIGHT: KEY_RIGHT,
		A: KEY_X,
		B: KEY_C,
		X: KEY_V,
		Y: KEY_B,
		L: KEY_A,
		R: KEY_Z,
		ZL: KEY_S,
		ZR: KEY_D,
		START: KEY_ENTER,
		SELECT: KEY_SHIFT
	},
	"input.axes": {
		UP: [JOY_ANALOG_LY, -1.0],
		DOWN: [JOY_ANALOG_LY, 1.0],
		LEFT: [JOY_ANALOG_LX, -1.0],
		RIGHT: [JOY_ANALOG_LX, 1.0]
	},
	"input.buttons": {
		UP: JOY_DPAD_UP,
		DOWN: JOY_DPAD_DOWN,
		LEFT: JOY_DPAD_LEFT,
		RIGHT: JOY_DPAD_RIGHT,
		A: JOY_DS_A,
		B: JOY_DS_B,
		X: JOY_DS_X,
		Y: JOY_DS_Y,
		L: JOY_L,
		ZL: JOY_L2,
		R: JOY_R,
		ZR: JOY_R2,
		START: JOY_START,
		SELECT: JOY_SELECT
	}
}
