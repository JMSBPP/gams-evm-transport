



    GAMS               ------            Idris    ----   plank
      Model


integraction interface through 

```
- <agent name1>:
    <root option1>: <value>
    <root option2>: <value>
    .
    .
    <root option3>:
      - <option1>: <value>
        <option2>: <value>
        .
        .
      - <option1>: <value>
        <option2>: <value>
        .
        .
      .
      .
- <agent name2>:
    .
    .
```

e.g 

- PythonCode:
    code: |
      print("Print from Python")
      # insert more Python code here

 code     Python code to be executed.   
 trace   0   Specify the trace level for debugging output.   

- agent: Reader | Transformer | Writer

> As a fist example we wnat the oython code to ping a server/connect to a server and ask for wahtever the gams module needs
> This is the syntax:

$onEmbeddedCode Connect:
	- PythonCode:
	   code: | method :: eg some script to run the idris code that actually interacts withn the db
$offEmbeddedCode


- what is the db ?

- well it is some query to an indexer:


1.

- Start a server


### REQUIREMENTS

For the python server we need a minismalistic interface that sends to idris the method in question. Then we need to first specify the method and communication semantics

python calls the idirs runtime that has the uinderlying method semantics. Then what are the communication semantics


Note that:

GAMSStdIn(i,j) = [Indexes(i) , Parameters(i,j)]

Indexes(i) : IndexKey -> SetQuery
Parameters(i,j): (IndexKey -> (ParameterKey -> ParameterKind) ) -> ParameterQuery
ParameterKind = Scalar | Vector | Matrix

GamsQuery = ParameterQuery | SetQuery 

GamsClient : GamsQuery -> GamsQueryState -> Response
GamsQueryState = Sent | Failed | Received
Response = Empty | Fill Empty

\(\forall_{q}\) GamsClient(q, Failed) = Empty

FoundryClient: GamsQuery -> GamsQueryState -> Response

\(\forall_{q} \, \)FoundryClient(q, Received) = Fill Empty


e.g

SupplyLocationA - > 'getSupplyLocationA'


GAMS {
	stdIn:: [
		      Sets,  // indexes   
              Parameters { Scalar, Vector, Matrix }
		 ], //  EXOGENOUS_VARIABLES
	 Model :: [
			 Variables, // ENDOGENOUS_VARIABLES
			 Equations // MODEL
     ],
	 stdOut:: [
		 Model and Solve Statements, 
		 Display Statements (optional),
		 Echo Prints,
		 Reference Maps,
		 Equation Listings,
		 Status Reports,
		 Solution Reports
	 ], 
}




What is GAMS responsability ?
What is Idris ?
What is plank ?

Under 
