module type Config = {let shape: DistTypes.xyShape;};

exception ShapeWrong(string);

let order = (shape: DistTypes.xyShape): DistTypes.xyShape => {
  let xy =
    shape.xs
    |> Array.mapi((i, x) => [x, shape.ys |> Array.get(_, i)])
    |> Belt.SortArray.stableSortBy(_, ([a, _], [b, _]) => a > b ? 1 : (-1));
  {
    xs: xy |> Array.map(([x, _]) => x),
    ys: xy |> Array.map(([_, y]) => y),
  };
};

module Make = (Config: Config) => {
  let xs = Config.shape.xs;
  let ys = Config.shape.ys;
  let get = Array.get;

  let validateHasLength = (): bool => Array.length(xs) > 0;
  let validateSize = (): bool => Array.length(xs) == Array.length(ys);
  if (!validateHasLength()) {
    raise(ShapeWrong("You need at least one element."));
  };
  if (!validateSize()) {
    raise(ShapeWrong("Arrays of \"xs\" and \"ys\" have different sizes."));
  };
  if (!Belt.SortArray.isSorted(xs, (a, b) => a > b ? 1 : (-1))) {
    raise(ShapeWrong("Arrays of \"xs\" and \"ys\" have different sizes."));
  };
  let minX = () => xs |> get(_, 0);
  let maxX = () => xs |> get(_, Array.length(xs) - 1);
  let minY = () => ys |> get(_, 0);
  let maxY = () => ys |> get(_, Array.length(ys) - 1);
  let findY = x => {
    let firstHigherIndex = Belt.Array.getIndexBy(xs, e => e > x);
    switch (firstHigherIndex) {
    | None => maxY()
    | Some(1) => minY()
    | Some(firstHigherIndex) =>
      let lowerOrEqualIndex =
        firstHigherIndex - 1 < 0 ? 0 : firstHigherIndex - 1;
      let needsInterpolation = get(xs, lowerOrEqualIndex) != x;
      if (needsInterpolation) {
        Functions.interpolate(
          get(xs, lowerOrEqualIndex),
          get(xs, firstHigherIndex),
          get(ys, lowerOrEqualIndex),
          get(ys, firstHigherIndex),
          x,
        );
      } else {
        ys[lowerOrEqualIndex];
      };
    };
  };
  1;
};
