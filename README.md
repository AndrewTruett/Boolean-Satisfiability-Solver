# Boolean Satisfiability Solver Using Non-determinism
## Background
The boolean satisfiability problem (SAT) is a classic problem in computer science. Given a boolean expression, the question is whether or not there exists a combination of true/false values for the boolean variables of that expression, such that the expression evaluates to true. For example, (a AND b) is satisfiable because there exists a combination of true/false values, namely a is true, and b is true, that results in the expression being true. An example of a non-satisfiable expression is (a AND (NOT a)). This is a contradiction, as there is no possible way to select a true/false value for a such that the expression will evaluate to true.

## Amb Operator and Assert
### Amb Operator
Ambiguous functions were first created by the inventor of the LISP programming language, John McCarthy. The amb operator is a huge asset when creating a non-deterministic alogorithm. The amb operator takes an arbitrary number of arguments and returns one of them. It is not guaranteed which argument will be returned at compile time. The value that gets returned by amb depends on constraints that can be enforced using the assert function.

### Assert Function
The assert function is used alongside the amb operator to create constraints that must be enforced. The assert function takes a predicate as an argument and evaluates it. If the predicate evaluates to true, nothing happens, but when the predicate evaluates to false, any values that were assigned using the amb operator, will automatically back track and be re-assigned such that the predicate evaluates to true.

### Examples
#### Using boolean values
```scheme
(let ((x (amb #t #f)))
  (assert (not x))
  (list x))
  ```
  Output: `(#f)`
 
#### Using numbers
 ```scheme
  (let ((x (amb 1 2 3))
        (y (amb 2 3 4)))
    (assert (< (+ x y) 4))
    (list x y))
  ```
  Output: `(1 2)`
  
  ## Procedures
  `(get-value)`
  
 Returns a call to amb with `#t` and `#f` as arguments.
 
 `(assign-vals vars)`
 
 Arguments: vars - a list of variable names (no duplicates)
 Returns an association list where each cell is in the form of `(variable_name, (get-value))`
 
 
