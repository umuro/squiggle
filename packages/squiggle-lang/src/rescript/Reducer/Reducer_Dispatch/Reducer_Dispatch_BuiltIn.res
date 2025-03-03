module ExternalLibrary = ReducerInterface.ExternalLibrary
module MathJs = Reducer_MathJs
open ReducerInterface.ExpressionValue
open Reducer_ErrorValue

/*
  MathJs provides default implementations for builtins
  This is where all the expected builtins like + = * / sin cos log ln etc are handled
  DO NOT try to add external function mapping here!
*/

exception TestRescriptException

let callInternal = (call: functionCall): result<'b, errorValue> => {
  let callMathJs = (call: functionCall): result<'b, errorValue> =>
    switch call {
    | ("javascriptraise", [msg]) => Js.Exn.raiseError(toString(msg)) // For Tests
    | ("rescriptraise", _) => raise(TestRescriptException) // For Tests
    | call => call->toStringFunctionCall->MathJs.Eval.eval
    }

  let constructRecord = arrayOfPairs => {
    Belt.Array.map(arrayOfPairs, pairValue => {
      switch pairValue {
      | EvArray([EvString(key), valueValue]) => (key, valueValue)
      | _ => ("wrong key type", pairValue->toStringWithType->EvString)
      }
    })
    ->Js.Dict.fromArray
    ->EvRecord
    ->Ok
  }

  let arrayAtIndex = (aValueArray: array<expressionValue>, fIndex: float) =>
    switch Belt.Array.get(aValueArray, Belt.Int.fromFloat(fIndex)) {
    | Some(value) => value->Ok
    | None => REArrayIndexNotFound("Array index not found", Belt.Int.fromFloat(fIndex))->Error
    }

  let recordAtIndex = (dict: Js.Dict.t<expressionValue>, sIndex) =>
    switch Js.Dict.get(dict, sIndex) {
    | Some(value) => value->Ok
    | None => RERecordPropertyNotFound("Record property not found", sIndex)->Error
    }

  switch call {
  // | ("$constructRecord", pairArray)
  // | ("$atIndex", [EvArray(anArray), EvNumber(fIndex)]) => arrayAtIndex(anArray, fIndex)
  // | ("$atIndex", [EvRecord(aRecord), EvString(sIndex)]) => recordAtIndex(aRecord, sIndex)
  | ("$constructRecord", [EvArray(arrayOfPairs)]) => constructRecord(arrayOfPairs)
  | ("$atIndex", [EvArray(aValueArray), EvArray([EvNumber(fIndex)])]) =>
    arrayAtIndex(aValueArray, fIndex)
  | ("$atIndex", [EvRecord(dict), EvArray([EvString(sIndex)])]) => recordAtIndex(dict, sIndex)
  | ("$atIndex", [obj, index]) =>
    (toStringWithType(obj) ++ "??~~~~" ++ toStringWithType(index))->EvString->Ok
  | call => callMathJs(call)
  }
}

/*
  Reducer uses Result monad while reducing expressions
*/
let dispatch = (call: functionCall): result<expressionValue, errorValue> =>
  try {
    let (fn, args) = call
    // There is a bug that prevents string match in patterns
    // So we have to recreate a copy of the string
    ExternalLibrary.dispatch((Js.String.make(fn), args), callInternal)
  } catch {
  | Js.Exn.Error(obj) => REJavaScriptExn(Js.Exn.message(obj), Js.Exn.name(obj))->Error
  | _ => RETodo("unhandled rescript exception")->Error
  }
