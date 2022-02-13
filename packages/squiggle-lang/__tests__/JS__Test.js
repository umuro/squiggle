var js = require("../src/js/index.js");

describe("A simple result", () => {
    test("mean(normal(5,2))", () => {
        expect(js.runMePlease("mean(normal(5,2))")).toEqual({ tag: 'Ok', value: { hd: { NAME: 'Float', VAL: 5 }, tl: 0 } });
    });
    test("mean(normal(5,2))", () => {
        let foo = js.runMePlease("mean(normal(5,2))");
        expect(foo).toEqual({"tag": "Ok", "value": {"hd": {"NAME": "Float", "VAL": 5}, "tl": 0}});
    });
    test.only("mean(mm(normal(5,2), normal(10,2)))", () => {
        let foo = js.runMePlease("mean(mm(normal(10,1),normal(10,11)))");
        expect(foo).toEqual({"tag": "Ok", "value": {"hd": {"NAME": "Float", "VAL": 10}, "tl": 0}});
    });
});