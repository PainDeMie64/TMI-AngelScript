# Scripting Docs

This scripting language evaluates conditions based on the simulation state. Every script must resolve to a Boolean (True/False) comparison.

### Operators
*   **Comparison:** `>`, `<`, `>=`, `<=`, `=`
*   **Arithmetic:** `+`, `-`, `*`, `/`
*   **Grouping:** `( ... )` for order of operations.

### Car Properties
**Floats**
*   `car.x`, `car.position.x`
*   `car.y`, `car.position.y`
*   `car.z`, `car.position.z`
*   `car.speed` (m/s)

**Vectors (vec3)**
*   `car.pos`, `car.position`
*   `car.vel`, `car.velocity`

### Functions
*   **`kmh(value)`**: Multiplies `value` by 3.6 (m/s to km/h).
*   **`distance(vec1, vec2)`**: Calculates Euclidean distance between two vectors.
*   **`variable("name")`**: Fetches a global string variable and parses it as a float or vec3.

### Data Types
*   **Numbers:** `10.5`, `-50`, `0`
*   **Vectors:** Defined by parentheses: `(100.0, 50.5, 20.0)`

### Examples

**Simple Speed Check**
```javascript
kmh(car.speed) > 500
```

**Position Check**
```javascript
car.z < 10.5
```

**Distance to fixed point**
```javascript
distance(car.pos, (105.5, 20.0, 300.0)) < 5.0
```

**Distance to dynamic variable (e.g., from bf single point settings)**
```javascript
distance(car.pos, variable("bf_target_point")) < 3.0
```

**Multiple lines**
```javascript
car.x < 3.0
car.y > -53
```
