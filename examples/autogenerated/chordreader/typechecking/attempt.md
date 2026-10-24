# Negative typechecking control

`answer : Int32` deliberately receives a Text literal. The maintained compiler
rejects the missing `FromString Int32` implementation with exit status1.
The build executes this negative control and requires the actual diagnostic.
Every host executable has a separate successful `--check -Werror` prerequisite
before code generation. This matters because invoking the compiler with `-o`
on invalid input can emit a partial launcher despite returning failure. Such a
launcher is never accepted or packaged. No application artifact bypasses the
checked front end.
