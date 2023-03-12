# yaobinwen.github.io

## Blog Theme

I'm using [_The Hacker theme_](https://github.com/pages-themes/hacker).

## Build & Serve

Run `./build-serve.sh` to build the site and serve locally.

Notes:
- 1. I'm building my own `ruby` Docker images in order to build and serve locally for local development.
- 2. The script `build-serve.sh` does everything: build the customized Docker image and run `jekyll serve` appropriately.

## Various Issues

Once I forgot to add the YAML front matter in `index.md`. As a result, `jekyll` didn't convert `index.md` to `index.html`. See the two references:
- [Jekyll site working on GitHub Pages not working locally](https://stackoverflow.com/q/64548430/630364)
- [Jekyll: Front Matter](https://jekyllrb.com/docs/front-matter/)

I dealt with the broken links from `index` page to the posts because I used hard links that were quite fragile. Refer to [`link` tag](https://jekyllrb.com/docs/liquid/tags/#links) on how to do it appropirately. See how it is used in `index.md`.

I needed to deal with displaying the literal `{{}}` in the middle of my post content. [How to escape liquid template tags?](https://stackoverflow.com/a/13582517/630364) told me to use `{% raw %}`. See how it is used in the post [_"Ansible: Understanding the `subelements` lookup (`with_subelements`)"_](_posts/2022/2022-01-07-Ansible-subelements.md).

I used [MathJax](https://docs.mathjax.org/en/latest/) to render mathematical expressions in the posts:
- In `_layouts/posts.html`, I added the `<script>` tags to include MathJax into the posts. Refer to [_MathJax - Getting Started - Web Integration_](https://www.mathjax.org/#gettingstarted).
- Refer to the article [_Information, Entropy, and Password Strength_](_posts/2023/2023-03-06-Information-Entropy-and-password-strength.md) on how to write inline and separate math expressions in Markerdown.
