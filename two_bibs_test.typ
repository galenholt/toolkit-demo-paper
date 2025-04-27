// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}

#import "@preview/fontawesome:0.5.0": *

#let preprint(
  // Document metadata
  title: none,
  running-head: none,
  authors: (),
  affiliations: none,
  abstract: none,
  categories: none,
  wordcount: none,
  authornote: none,
  citation: none,
  date: none,
  branding: none,
  // Layout settings
  leading: 0.6em,
  spacing: 0.6em,
  first-line-indent: 1.8em,
  all: false,
  linkcolor: black,
  margin: (x: 3.2cm, y: 3cm),
  paper: "a4",
  // Typography settings
  lang: "en",
  region: "US",
  font: ("Times", "Times New Roman", "Arial"),
  fontsize: 11pt,
  // Structure settings
  section-numbering: none,
  toc: false,
  toc-title: none,
  toc-depth: none,
  toc-indent: 1.5em,
  bibliography-title: "References",
  bibliography-style: "apa",
  cols: 1,
  col-gutter: 4.2%,
  doc,
) = {
  /* Document settings */
  // Link and cite colors
  show link: set text(fill: linkcolor)
  show cite: set text(fill: linkcolor)

  // Allow custom title for bibliography section
  set bibliography(title: bibliography-title, style: bibliography-style)

  // Bibliography paragraph spacing
  show bibliography: set par(spacing: spacing, leading: leading)

  // Space around figures
  show figure: f => { [#v(leading * 2) #f #v(leading * 2) ] }

  /* Page layout settings */
  set page(
    paper: paper,
    margin: margin,
    numbering: none,
    header-ascent: 50%,
    header: context {
      if (counter(page).get().at(0) > 1) [
        #grid(
          columns: (1fr, 1fr),
          align(left)[#running-head], align(right)[#counter(page).display()],
        )
      ]
    },
    footer-descent: 10%,
  )

  /* Typography settings */

  // Paragraph settings
  set par(
    justify: true,
    leading: leading,
    spacing: spacing,
    first-line-indent: (amount: first-line-indent, all: all),
  )

  // Text settings
  set text(
    lang: lang,
    region: region,
    font: font,
    size: fontsize,
  )

  // Headers
  set heading(numbering: section-numbering)
  show heading.where(level: 1): it => block(width: 100%, below: 1em, above: 1.25em)[
    #set align(center)
    #set text(size: fontsize * 1.1, weight: "bold")
    #it
  ]
  show heading.where(level: 2): it => block(width: 100%, below: 1em, above: 1.25em)[
    #set text(size: fontsize * 1.05)
    #it
  ]
  show heading.where(level: 3): it => block(width: 100%, below: 0.8em, above: 1.2em)[
    #set text(size: fontsize, style: "italic")
    #it
  ]
  // Level 4 & 5 headers are in paragraph
  show heading.where(level: 4): it => box(
    inset: (top: 0em, bottom: 0em, left: 0em, right: 0.1em),
    text(size: 1em, weight: "bold", it.body + [.]),
  )
  show heading.where(level: 5): it => box(
    inset: (top: 0em, bottom: 0em, left: 0em, right: 0.1em),
    text(size: 1em, weight: "bold", style: "italic", it.body + [.]),
  )

  /* Front matter formatting */

  let titleblock(
    body,
    width: 100%,
    size: 1.5em,
    weight: "bold",
    above: 1em,
    below: 0em,
  ) = [
    #align(center)[
      #block(width: width, above: above, below: below)[
        #text(weight: weight, size: size, hyphenate: false)[#body]
      ]
    ]
  ]

  if title != none {
    titleblock(title, above: 0em, below: 2em)
  }

  /* Author formatting */

  // Format author strings here, so can use in author note
  let author_strings = ()
  let equal_contributors = ()

  if authors != none {
    // First pass: collect equal contributors
    for a in authors {
      if a.keys().contains("equal-contributor") and a.at("equal-contributor") == true {
        equal_contributors.push(a.name)
      }
    }

    // Create equal contributor note text to reuse
    let equal_contrib_text = none
    if equal_contributors.len() > 1 {
      equal_contrib_text = [#equal_contributors.join(", ", last: " & ") contributed equally to this work.]
    }

    // Second pass: build author display strings with attached footnotes
    for a in authors {
      let author_elements = (a.name,)

      // Add affiliation superscript for multi-author papers
      if authors.len() > 1 {
        author_elements.push(super(a.affiliation))
      }

      // Add equal contributor marker if needed
      if a.keys().contains("equal-contributor") and a.at("equal-contributor") == true and equal_contributors.len() > 1 {
        author_elements.push(super[§])
      }

      // Add corresponding author footnote directly to the author name
      if a.keys().contains("corresponding") {
        author_elements.push(
          footnote(
            numbering: "*",
            [
              Send correspondence to: #a.name, #a.email.
              #if equal_contrib_text != none [
                #super[§]#equal_contrib_text
              ]
              #if authornote != none [#authornote]
            ],
          ),
        )
      }

      // Add ORCID if available
      if a.keys().contains("orcid") {
        author_elements.push(link(a.orcid, fa-orcid(fill: rgb("a6ce39"), size: 0.8em)))
      }

      // Add author string to the list
      author_strings.push(box(author_elements.join()))
    }
  }

  if authors != none {
    titleblock(
      weight: "regular",
      size: 1.25em,
      [#author_strings.join(", ", last: " & ")],
    )
  }

  if affiliations != none {
    titleblock(
      weight: "regular",
      size: 1.1em,
      below: 2em,
      for a in affiliations [
        #if authors.len() > 1 [#super[#a.id]]#a.name#if a.keys().contains("department") [, #a.department] \
      ],
    )
  }

  // Reset footnote counter for the main document
  counter(footnote).update(0)

  /* Abstract and metadata section */

  block(inset: (top: 1em, bottom: 0em, left: 2.4em, right: 2.4em))[
    #set text(size: 0.92em)
    #set par(first-line-indent: 0em)
    #if abstract != none {
      abstract
    }
    #if categories != none {
      [#v(0.4em)#text(style: "italic")[Keywords:] #categories]
    }
    #if wordcount != none {
      [\ #text(style: "italic")[Words:] #wordcount]
    }
  ]

  // Table of contents
  if toc {
    block(inset: (top: 2em, bottom: 0em, left: 2.4em, right: 2.4em))[
      #outline(
        title: toc-title,
        depth: toc-depth,
        indent: toc-indent,
      )
    ]
  }

  /* Document content */

  // Separate content a bit from front matter
  v(2em)

  // Show document content with cols if specified
  if cols == 1 {
    doc
  } else {
    columns(
      cols,
      gutter: col-gutter,
      doc,
    )
  }
}

// Remove gridlines from tables
#set table(
  inset: 6pt,
  stroke: none,
)

#show: doc => preprint(
  title: [Two Bibs],
  authors: (
        (
        name: [Galen Holt],
        affiliation: [1],
        corresponding: true,
        
        orcid: "https://orcid.org/0000-0002-7455-9275",
        email: [galen\@deakin.edu.au]
      ),
    ),
  affiliations: (
    (
      id: "1",
      name: "Deakin University",
      department: "Centre for Regional and Rural Futures"
    ),
    
  ),
  date: [2025-04-26],
  section-numbering: "1.1.a",
  toc-depth: 3,
  toc-title: "Table of contents",
  doc,
)

= Main
<main>
I want a couple cites here @holt2024@ziolkowska2016.

== References
<references>
#block[
] <refs_main>
#pagebreak()
= Supp
<supp>
And one the same and one different here @holt2024@brown2009.

== References
<references-1>
#block[
] <refs_supp>


 
  
#set bibliography(style: "freshwater-biology.csl") 


