<script>
/* eslint-disable vue/no-v-html */
import marked from 'marked';
import katex from 'katex';
import { sanitize } from '~/lib/dompurify';
import Prompt from './prompt.vue';

const renderer = new marked.Renderer();

/*
    Regex to match KaTex blocks.

    Supports the following:

    \begin{equation}<math>\end{equation}
    $$<math>$$
    inline $<math>$

    The matched text then goes through the KaTex renderer & then outputs the HTML
  */
const katexRegexString = `(
    ^\\\\begin{[a-zA-Z]+}\\s
    |
    ^\\$\\$
    |
    \\s\\$(?!\\$)
  )
    ((.|\\n)+?)
  (
    \\s\\\\end{[a-zA-Z]+}$
    |
    \\$\\$$
    |
    \\$
  )
  `
  .replace(/\s/g, '')
  .trim();

function renderKatex(t) {
  let text = t;
  let numInline = 0; // number of successfull converted math formulas

  if (typeof katex !== 'undefined') {
    const katexString = text
      .replace(/&amp;/g, '&')
      .replace(/&=&/g, '\\space=\\space') // eslint-disable-line @gitlab/require-i18n-strings
      .replace(/<(\/?)em>/g, '_');
    const regex = new RegExp(katexRegexString, 'gi');
    const matchLocation = katexString.search(regex);
    const numberOfMatches = katexString.match(regex);

    if (numberOfMatches && numberOfMatches.length !== 0) {
      let matches = regex.exec(katexString);
      if (matchLocation > 0) {
        numInline += 1;

        while (matches !== null) {
          try {
            const renderedKatex = katex.renderToString(
              matches[0].replace(/\$/g, '').replace(/&#39;/g, "'"),
            ); // get the tick ' back again from HTMLified string
            text = `${text.replace(matches[0], ` ${renderedKatex}`)}`;
          } catch {
            numInline -= 1;
          }
          matches = regex.exec(katexString);
        }
      } else {
        try {
          text = katex.renderToString(matches[2].replace(/&#39;/g, "'"));
        } catch (error) {
          numInline -= 1;
        }
      }
    }
  }
  return [text, numInline > 0];
}
renderer.paragraph = (t) => {
  const [text, inline] = renderKatex(t);
  return `<p class="${inline ? 'inline-katex' : ''}">${text}</p>`;
};
renderer.listitem = (t) => {
  const [text, inline] = renderKatex(t);
  return `<li class="${inline ? 'inline-katex' : ''}">${text}</li>`;
};

marked.setOptions({
  renderer,
});

export default {
  components: {
    prompt: Prompt,
  },
  props: {
    cell: {
      type: Object,
      required: true,
    },
  },
  computed: {
    markdown() {
      return sanitize(marked(this.cell.source.join('').replace(/\\/g, '\\\\')), {
        // allowedTags from GitLab's inline HTML guidelines
        // https://docs.gitlab.com/ee/user/markdown.html#inline-html
        ALLOWED_TAGS: [
          'a',
          'abbr',
          'b',
          'blockquote',
          'br',
          'code',
          'dd',
          'del',
          'div',
          'dl',
          'dt',
          'em',
          'h1',
          'h2',
          'h3',
          'h4',
          'h5',
          'h6',
          'hr',
          'i',
          'img',
          'ins',
          'kbd',
          'li',
          'ol',
          'p',
          'pre',
          'q',
          'rp',
          'rt',
          'ruby',
          's',
          'samp',
          'span',
          'strike',
          'strong',
          'sub',
          'summary',
          'sup',
          'table',
          'tbody',
          'td',
          'tfoot',
          'th',
          'thead',
          'tr',
          'tt',
          'ul',
          'var',
        ],
        ALLOWED_ATTR: ['class', 'style', 'href', 'src'],
      });
    },
  },
};
</script>

<template>
  <div class="cell text-cell">
    <prompt />
    <div class="markdown" v-html="markdown"></div>
  </div>
</template>

<style>
/*
  Importing the necessary katex stylesheet from the node_module folder rather
  than copying the stylesheet into `app/assets/stylesheets/vendors` for
  automatic importing via `app/assets/stylesheets/application.scss`. The reason
  is that the katex stylesheet depends on many fonts that are in node_module
  subfolders - moving all these fonts would make updating katex difficult.
 */
@import '~katex/dist/katex.min.css';

.markdown .katex {
  display: block;
  text-align: center;
}

.markdown .inline-katex .katex {
  display: inline;
  text-align: initial;
}
</style>
