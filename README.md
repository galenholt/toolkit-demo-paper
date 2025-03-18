# toolkit-demo-paper
This builds the demo paper. It's based on the [toolkit demo
website](https://mdbauth.github.io/WERP_toolkit_demo/), but I've moved it here
so we can edit without being public. That means we need to access the
`more_scenarios` folders to get shared figures and outputs (and it should share
`images` but currently does not). I've set things up so this shares a common
outer directory, so access is by `../WERP_toolkit_demo`.

Both the demo and this need to be run from the current version of the toolkit
and have the current version of the EWR tool.

```
poetry add py-ewr
renv::install('git@github.com:MDBAuth/WERP_toolkit.git@master', rebuild = TRUE, upgrade = 'always', git = 'external', prompt = FALSE)
```

The rendered website, along with links to a word doc and pdf are at
[https://animated-doodle-4g9vwqm.pages.github.io/presentation_paper/demo_paper.html](https://animated-doodle-4g9vwqm.pages.github.io/presentation_paper/demo_paper.html).
In-html highlighting is available- select some text, click the Annotate button,
and it'll prompt you to create a [Hypothes.is](https://web.hypothes.is/)
account. Comments are public by default, but let me know once you have an
account and I'll create a private group.
Any other questions, contact Galen.
