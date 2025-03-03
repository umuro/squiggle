module ErrorValue = Reducer_ErrorValue
module ExpressionValue = ReducerInterface.ExpressionValue
module ExpressionT = Reducer_Expression_T
module JavaScript = Reducer_Js
module Parse = Reducer_MathJs_Parse
module Result = Belt.Result

type expression = ExpressionT.expression
type expressionValue = ExpressionValue.expressionValue
type errorValue = ErrorValue.errorValue

let passToFunction = (fName: string, rLispArgs): result<expression, errorValue> => {
  let toEvCallValue = (name: string): expression => name->ExpressionValue.EvCall->ExpressionT.EValue

  let fn = fName->toEvCallValue
  rLispArgs->Result.flatMap(lispArgs => list{fn, ...lispArgs}->ExpressionT.EList->Ok)
}

type blockTag =
  | ImportVariablesStatement
  | ExportVariablesExpression
type tagOrNode =
  | BlockTag(blockTag)
  | BlockNode(Parse.node)

let toTagOrNode = block => BlockNode(block["node"])

let rec fromNode = (mathJsNode: Parse.node): result<expression, errorValue> =>
  Parse.castNodeType(mathJsNode)->Result.flatMap(typedMathJsNode => {
    let fromNodeList = (nodeList: list<Parse.node>): result<list<expression>, 'e> =>
      Belt.List.reduceReverse(nodeList, Ok(list{}), (racc, currNode) =>
        racc->Result.flatMap(acc =>
          fromNode(currNode)->Result.map(currCode => list{currCode, ...acc})
        )
      )

    let toEvSymbolValue = (name: string): expression =>
      name->ExpressionValue.EvSymbol->ExpressionT.EValue

    let caseFunctionNode = fNode => {
      let lispArgs = fNode["args"]->Belt.List.fromArray->fromNodeList
      passToFunction(fNode->Parse.nameOfFunctionNode, lispArgs)
    }

    let caseObjectNode = oNode => {
      let fromObjectEntries = entryList => {
        let rargs = Belt.List.reduceReverse(entryList, Ok(list{}), (
          racc,
          (key: string, value: Parse.node),
        ) =>
          racc->Result.flatMap(acc =>
            fromNode(value)->Result.map(valueExpression => {
              let entryCode =
                list{
                  key->ExpressionValue.EvString->ExpressionT.EValue,
                  valueExpression,
                }->ExpressionT.EList
              list{entryCode, ...acc}
            })
          )
        )
        rargs->Result.flatMap(args =>
          passToFunction("$constructRecord", list{ExpressionT.EList(args)}->Ok)
        ) // $consturctRecord gets a single argument: List of key-value paiers
      }

      oNode["properties"]->Js.Dict.entries->Belt.List.fromArray->fromObjectEntries
    }

    let caseIndexNode = iNode => {
      let rpropertyCodeList = Belt.List.reduceReverse(
        iNode["dimensions"]->Belt.List.fromArray,
        Ok(list{}),
        (racc, currentPropertyMathJsNode) =>
          racc->Result.flatMap(acc =>
            fromNode(currentPropertyMathJsNode)->Result.map(propertyCode => list{
              propertyCode,
              ...acc,
            })
          ),
      )
      rpropertyCodeList->Result.map(propertyCodeList => ExpressionT.EList(propertyCodeList))
    }

    let caseAccessorNode = (objectNode, indexNode) => {
      caseIndexNode(indexNode)->Result.flatMap(indexCode => {
        fromNode(objectNode)->Result.flatMap(objectCode =>
          passToFunction("$atIndex", list{objectCode, indexCode}->Ok)
        )
      })
    }

    let caseAssignmentNode = aNode => {
      let symbol = aNode["object"]["name"]->toEvSymbolValue
      let rValueExpression = fromNode(aNode["value"])
      rValueExpression->Result.flatMap(valueExpression => {
        let lispArgs = list{symbol, valueExpression}->Ok
        passToFunction("$let", lispArgs)
      })
    }

    let caseArrayNode = aNode => {
      aNode["items"]->Belt.List.fromArray->fromNodeList->Result.map(list => ExpressionT.EList(list))
    }

    let rFinalExpression: result<expression, errorValue> = switch typedMathJsNode {
    | MjAccessorNode(aNode) => caseAccessorNode(aNode["object"], aNode["index"])
    | MjArrayNode(aNode) => caseArrayNode(aNode)
    | MjAssignmentNode(aNode) => caseAssignmentNode(aNode)
    | MjSymbolNode(sNode) => {
        let expr: expression = toEvSymbolValue(sNode["name"])
        let rExpr: result<expression, errorValue> = expr->Ok
        rExpr
      }
    | MjBlockNode(bNode) => bNode["blocks"]->Belt.Array.map(toTagOrNode)->caseTagOrNodes
    | MjConstantNode(cNode) =>
      cNode["value"]->JavaScript.Gate.jsToEv->Result.flatMap(v => v->ExpressionT.EValue->Ok)
    | MjFunctionNode(fNode) => fNode->caseFunctionNode
    | MjIndexNode(iNode) => caseIndexNode(iNode)
    | MjObjectNode(oNode) => caseObjectNode(oNode)
    | MjOperatorNode(opNode) => opNode->Parse.castOperatorNodeToFunctionNode->caseFunctionNode
    | MjParenthesisNode(pNode) => pNode["content"]->fromNode
    }
    rFinalExpression
  })
and caseTagOrNodes = (tagOrNodes): result<expression, errorValue> => {
  let initialBindings = passToFunction("$$bindings", list{}->Ok)
  let lastIndex = Belt.Array.length(tagOrNodes) - 1
  tagOrNodes->Belt.Array.reduceWithIndex(initialBindings, (rPreviousBindings, tagOrNode, i) => {
    rPreviousBindings->Result.flatMap(previousBindings => {
      let rStatement: result<expression, errorValue> = switch tagOrNode {
      | BlockNode(node) => fromNode(node)
      | BlockTag(tag) =>
        switch tag {
        | ImportVariablesStatement => passToFunction("$importVariablesStatement", list{}->Ok)
        | ExportVariablesExpression => passToFunction("$exportVariablesExpression", list{}->Ok)
        }
      }

      let bindName = if i == lastIndex {
        "$$bindExpression"
      } else {
        "$$bindStatement"
      }

      rStatement->Result.flatMap((statement: expression) => {
        let lispArgs = list{previousBindings, statement}->Ok
        passToFunction(bindName, lispArgs)
      })
    })
  })
}

let fromPartialNode = (mathJsNode: Parse.node): result<expression, errorValue> => {
  Parse.castNodeType(mathJsNode)->Result.flatMap(typedMathJsNode => {
    let casePartialBlockNode = (bNode: Parse.blockNode) => {
      let blocksOrTags = bNode["blocks"]->Belt.Array.map(toTagOrNode)
      let completed = Js.Array2.concat(blocksOrTags, [BlockTag(ExportVariablesExpression)])
      completed->caseTagOrNodes
    }

    let casePartialExpression = (node: Parse.node) => {
      let completed = [BlockNode(node), BlockTag(ExportVariablesExpression)]

      completed->caseTagOrNodes
    }

    let rFinalExpression: result<expression, errorValue> = switch typedMathJsNode {
    | MjBlockNode(bNode) => casePartialBlockNode(bNode)
    | _ => casePartialExpression(mathJsNode)
    }
    rFinalExpression
  })
}

let fromOuterNode = (mathJsNode: Parse.node): result<expression, errorValue> => {
  Parse.castNodeType(mathJsNode)->Result.flatMap(typedMathJsNode => {
    let casePartialBlockNode = (bNode: Parse.blockNode) => {
      let blocksOrTags = bNode["blocks"]->Belt.Array.map(toTagOrNode)
      let completed = blocksOrTags
      completed->caseTagOrNodes
    }

    let casePartialExpression = (node: Parse.node) => {
      let completed = [BlockNode(node)]
      completed->caseTagOrNodes
    }

    let rFinalExpression: result<expression, errorValue> = switch typedMathJsNode {
    | MjBlockNode(bNode) => casePartialBlockNode(bNode)
    | _ => casePartialExpression(mathJsNode)
    }
    rFinalExpression
  })
}
