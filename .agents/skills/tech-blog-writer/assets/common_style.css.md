<style>
/* Markdown から HTML にするときは 以下の css を 全部 Markdown に書く */
body {
  /* Markdown に書くときは コメントを外す */
  margin-left: 5em;
}

/* 見出し関係のスタイル */
h1 {
  padding-top: 1em;
  padding-bottom: 0.3em;
  font-weight: bold;
  line-height: 1.2;
  border-bottom-width: 1px;
  border-bottom-style: solid;
  border-bottom-color: #c0c0c0;
}

h2 {
  padding-top: 1em;
  padding-bottom: 0.3em;
  font-weight: bold;
  line-height: 1.2;
  border-bottom-width: 1px;
  border-bottom-style: solid;
  border-bottom-color: #c0c0c0;
}

h3 {
  padding-top: 0.5em;
  font-weight: bold;
  text-decoration: underline;
}

h4 {
  padding-top: 0.5em;
  font-weight: bold;
  text-decoration: underline;
}

h5 {
  padding-top: 0.5em;
  font-weight: bold;
  text-decoration: underline;
}


strong {
  color: rgb(255, 150, 0);
  font-weight: bold;
}

/* html を自動生成したときに色を変える */
/* for inline code */
:not(pre):not(.hljs) > code {
  /* Change the old color so it seems less like an error */
  color: #FD3067;
  font-size: inherit;
}

/* 折りたたみ の <details> の 要素にインデントを付ける */
.details-content-indent {
  margin-left: 2em;
}
</style>
