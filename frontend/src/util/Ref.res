let exchange = (r, v) => {
  let cur = r.contents
  r.contents = v
  cur
}

let update = (r, fn) => exchange(r, fn(r.contents))
