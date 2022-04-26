import { run, squiggleExpression, errorValueToString } from "../src/js/index";
import _ from "lodash";

let testRun = (x: string): squiggleExpression => {
  let result = run(x, { sampleCount: 100, xyPointLength: 100 });
  if (result.tag === "Ok") {
    return result.value;
  } else {
    throw Error(
      "Expected squiggle expression to evaluate but got error: " +
        errorValueToString(result.value)
    );
  }
};

export function test(name: string, fn: () => void) {
  console.log(name);
  fn();
}

export function expectEqual(expression1: string, expression2: string) {
  let result1 = testRun(expression1);
  let result2 = testRun(expression2);
  if (result1.tag === "number" && result2.tag === "number") {
    let loss = getLoss(result1.value, result2.value);
    console.log(`${expression1} === ${expression2}`);
    console.log(`${result1.value} === ${result2.value}`);
    console.log(`loss = ${loss}`);
    console.log(`logloss = ${Math.abs(Math.log(result1.value) - Math.log(result2.value))}`);
    console.log()
  }
  else {
    throw Error(`Expected both to be number, but got ${result1.tag} and ${result2.tag}`)
  }
}

let getLoss = (actual: number, expected: number): number =>
  Math.abs(expected - actual);
