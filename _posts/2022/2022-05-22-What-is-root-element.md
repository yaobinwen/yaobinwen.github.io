---
comments: true
date: 2022-05-22
layout: post
tags: [Tech,Frontend,MUI]
title: "MUI: What is the 'root element' and how to read its document?"
---

When reading the documentation of [MUI](https://mui.com/), I find it sometimes uses the term "root element". For example, [the document for the prop `href` of `button` says this](https://mui.com/material-ui/api/button/#props):

> | Name | Type | Default | Description |
> |:----:|:----:|:-------:|:-----------:|
> | href | string || The URL to link to when the button is clicked. If defined, an `a` element will be used as the **root node**. |

Right below the `Props` section, the document also says:

> The ref is forwarded to the **root element**.

The [section _CSS_](https://mui.com/material-ui/api/button/#css) also says:

> | Rule name | Global class | Description |
> |:---------:|:------------:|:-----------:|
> |root | .MuiButton-root | Styles applied to the **root element**. |

So I've been a bit confused by the term "root element" because the MDN page [_`<html>`: The HTML Document / Root element_](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/html) says:

> The `<html>` HTML element represents the root (top-level element) of an HTML document, so it is also referred to as the _root_ element.

However, the "root element/node" that MUI document says is clearly not the element `<html>`. So what is it?

The answer to this question may be obvious to a frontend development veteran, but that doesn't seem to be obvious to me yet. After reading more about it, I realized the "root element" in MUI document is all about **the relative root HTML element in a nested structure**. To understand this, we need to think more about the native HTML elements and how a React.js component is implemented.

Let's use the HTML tag `<a>` as the example. When we want to implement a simple clickable hyperlink to another page, we can just use `<a>` by itself, as shown [in this W3Schools example](https://www.w3schools.com/tags/tryit.asp?filename=tryhtml_link_test):

```html
<!DOCTYPE html>
<html>
<body>

<h1>The a element</h1>

<a href="https://www.w3schools.com">Visit W3Schools.com!</a>

</body>
</html>
```

However, if we want to use an image or a button as the "clickable object" that takes the user to another page, we will need to use a nested structure by wrapping an `<img>` or `<button>` HTML element inside `<a>`, as shown [in this modified version of W3Schools example](https://www.w3schools.com/tags/tryit.asp?filename=tryhtml_link_image):

```html
<!DOCTYPE html>
<html>
<body>

<p>
  An image as a link:
  <a href="https://www.w3schools.com">
    <img border="0" alt="W3Schools" src="logo_w3s.gif" width="100" height="100">
  </a>
</p>

<p>
  A button as a link:
  <a href="https://www.w3schools.com">
    <button type="button">W3Schools Homepage</button>
  </a>
</p>

</body>
</html>
```

If we ignore the `<p>` tag in the example, the `<a>` along with the wrapped `<img>` and `<button>` creates a nested structure, and if we look at the structure as a whole entity, `<a>` is the **root element**. This doesn't conflict with the fact that `<html>` is the root element of the entire HTML document.

Then let's think about how a React.js component is implemented. No matter how fancy a component looks like, in the end, they all need to use the native HTML elements (plus CSS) to implement them. Some React.js components may correspond to one native HTML element; some other components may need multiple native HTML elements to implement. However, whether using one or multiple native HTML elements is an implementation detail that we should not assume but always refer to the documentation.

Take [the component `<Menu>`](https://mui.com/material-ui/api/menu/) for example. The MUI v5 document doesn't mention this explicitly, but the [v4 document](https://v4.mui.com/api/menu/) says:

> Any other props supplied will be provided to the root element (`Popover`).

If you look at the structure of the native HTML elements (by reading the class names), you will find that a `<Menu>` component is implemented in the following structure (see the screenshot below):

- Root `<div>` for `<Popover>` which is the root for `<Menu>` and implements the "pop over" behavior.
  - `<div>` for `<Paper>` which is the area on which the menu list is drawn.
    - `<ul>` for `<MenuList>` which is the list of menu items.
      - `<li>` for `<MenuItem>` which is each individual menu item.

![`<Menu>` structure in native HTML elements](../../images/2022/05-22/menu-structure.png)

`<Menu>`'s section _Props_ also mentions the props `MenuListProps`, `PopoverClasses`, and `TransitionProps`, which to some extent verifies that `<Menu>` is implemented using these more fundamental components which will correspond to the native HTML elements (`<div>`, `<ul>`, and `<li>`).

Therefore, when the `<Menu>`'s CSS section says "(`.MuiMenu-root` are the styles that) applied to the root element", it means those styles will be applied to the `<div>` element that's used to implement the `<Popover>` component.

Similarly, `.MuiMenu-paper` are the styles that are applied to the `<div>` element that's used to implement the `<Paper>` component, and `.MuiMenu-list`.

Unfortunately, MUI documentation of v5 doesn't seem to mention explicitly which component or native HTML element is used as the "root element" (but its v4 document usually, although not always, mentions that). I think it's because the components are customizable and can support different behaviors so the root element may be different in different cases. It looks like the only way is to use the developer's tools of the browser to determine the real root element of a component, as I did above to `<Menu>`.
