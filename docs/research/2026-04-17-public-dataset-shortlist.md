# Public Dataset And Tool-Data Shortlist

Accessed: 2026-04-17

## Student behavior / wellbeing datasets

### StudentLife
- URL: https://studentlife.cs.dartmouth.edu/dataset/
- Why it fits:
  - smartphone sensing + EMA + survey + educational data
  - includes stress, mood, sleep, activity, deadlines, grades, and Piazza usage
  - strong fit for stress-aware recommendation experiments

### OULAD
- URL: https://analyse.kmi.open.ac.uk/open-dataset
- Why it fits:
  - anonymised learning analytics dataset with courses, students, assessments, and VLE interactions
  - openly downloadable under CC-BY 4.0
  - useful for workload, engagement, and course-risk features

### ASSISTments
- URL: https://sites.google.com/site/assistmentsdata/home/2009-2010-assistment-data
- Why it fits:
  - open educational support / mastery-learning records
  - useful for academic-support and intervention experiments
  - complements stress-focused datasets with direct tutoring/learning signals

## Tool / skill datasets for agent systems

### ToolBench
- URL: https://github.com/OpenBMB/ToolBench
- Why it fits:
  - large single-tool and multi-tool instruction dataset
  - includes tool environment data, retrieval data, and annotated solution paths
  - useful for bootstrapping prompt/tool behaviors for multi-agent skill generation

### Gorilla / BFCL
- URL: https://github.com/ShishirPatil/gorilla
- Why it fits:
  - active tool-calling evaluation stack
  - BFCL includes multi-step and agentic tool-use scenarios
  - strong reference point for executable tool-use skill prompts

### APIBench
- URL: https://github.com/JohnnyPeng18/APIBench
- Why it fits:
  - benchmark for query-based and code-based API recommendation
  - useful when evaluating which tools or APIs should be suggested for a given support task

## How this branch uses them

- the app-level evaluation fixture stays lightweight and reproducible by sampling 40 users from the existing local UMD support dataset
- this shortlist is the next-step source set for replacing or augmenting that fixture with more realistic public data in future experiments
