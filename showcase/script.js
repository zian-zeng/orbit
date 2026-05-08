(function () {
  const navToggle = document.querySelector("[data-nav-toggle]");
  const navLinks = document.querySelector("[data-nav-links]");
  const header = document.querySelector("[data-header]");
  const backToTop = document.querySelector("[data-back-to-top]");
  const languageToggle = document.querySelector("[data-language-toggle]");
  const languageLabel = document.querySelector("[data-language-label]");
  const translations = {
    en: {
      "nav.problem": "Problem",
      "nav.overview": "Overview",
      "nav.story": "Our Story",
      "nav.how": "How It Works",
      "nav.walkthrough": "Walkthrough",
      "nav.architecture": "Architecture",
      "nav.run": "Run",
      "hero.eyebrow": "Student success operating layer",
      "hero.tagline": "Personalized multi-agent AI for student life, academic planning, campus logistics, and wellbeing.",
      "hero.value": "ORBIT helps college students coordinate schoolwork, stress, campus resources, food, routes, courses, calendars, and action cards from one explainable AI workspace. It is built around labels, specialist agents, tool routing, demo-safe data, and inspectable traces rather than a generic prompt-response chat flow.",
      "hero.explore": "Explore the Product",
      "hero.story": "Read Our Story",
      "hero.run": "Run the Project",
      "hero.mode": "Mode",
      "hero.modeText": "Local-first demo with opt-in live connectors",
      "hero.repo": "GitHub Repository",
      "hero.persona": "Persona",
      "hero.personaText": "Maya Chen, seeded UMD student profile",
      "hero.system": "System",
      "hero.systemText": "Labels -> agents -> tools -> action surfaces"
    },
    zh: {
      "nav.problem": "问题",
      "nav.overview": "概览",
      "nav.story": "我们的故事",
      "nav.how": "工作机制",
      "nav.walkthrough": "产品演示",
      "nav.architecture": "架构",
      "nav.run": "运行",
      "hero.eyebrow": "学生成功操作层",
      "hero.tagline": "面向学生生活、学业规划、校园后勤与身心支持的个性化多智能体 AI。",
      "hero.value": "ORBIT 帮助大学生在一个可解释的 AI 工作空间中协调课程任务、压力、校园资源、食物、路线、选课、日历和行动卡片。它围绕标签、专业智能体、工具路由、演示安全数据和可检查 traces 构建，而不是普通的 prompt-response 聊天流程。",
      "hero.explore": "查看产品",
      "hero.story": "阅读我们的故事",
      "hero.run": "运行项目",
      "hero.mode": "模式",
      "hero.modeText": "本地优先 demo，并支持可选 live connectors",
      "hero.repo": "GitHub 仓库",
      "hero.persona": "人物",
      "hero.personaText": "Maya Chen，预置的 UMD 学生画像",
      "hero.system": "系统",
      "hero.systemText": "标签 -> 智能体 -> 工具 -> 行动界面"
    }
  };
  const textTranslations = {
    "ORBIT | Personalized Multi-Agent AI for Student Life": "ORBIT | 面向学生生活的个性化多智能体 AI",
    "ORBIT | Our Story": "ORBIT | 我们的故事",
    "Skip to content": "跳转到正文",
    "Problem": "问题",
    "Overview": "概览",
    "Our Story": "我们的故事",
    "How It Works": "工作机制",
    "Walkthrough": "产品演示",
    "Architecture": "架构",
    "Run": "运行",
    "Toggle navigation": "切换导航",
    "Student success operating layer": "学生成功操作层",
    "Personalized multi-agent AI for student life, academic planning, campus logistics, and wellbeing.": "面向学生生活、学业规划、校园后勤与身心支持的个性化多智能体 AI。",
    "ORBIT helps college students coordinate schoolwork, stress, campus resources, food, routes, courses, calendars, and action cards from one explainable AI workspace. It is built around labels, specialist agents, tool routing, demo-safe data, and inspectable traces rather than a generic prompt-response chat flow.": "ORBIT 帮助大学生在一个可解释的 AI 工作空间中协调课程任务、压力、校园资源、食物、路线、选课、日历和行动卡片。它围绕标签、专业智能体、工具路由、演示安全数据和可检查 traces 构建，而不是普通的 prompt-response 聊天流程。",
    "Explore the Product": "查看产品",
    "Read Our Story": "阅读我们的故事",
    "Run the Project": "运行项目",
    "Mode": "模式",
    "Local-first demo with opt-in live connectors": "本地优先 demo，并支持可选 live connectors",
    "GitHub Repository": "GitHub 仓库",
    "Persona": "人物",
    "Maya Chen, seeded UMD student profile": "Maya Chen，预置的 UMD 学生画像",
    "System": "系统",
    "Labels -> agents -> tools -> action surfaces": "标签 -> 智能体 -> 工具 -> 行动界面",
    "Project Build Story": "项目构建故事",
    "Why We Built ORBIT, How We Built It, and What We Think It Proves": "我们为什么构建 ORBIT、如何实现它，以及它证明了什么",
    "ORBIT started from a team question that felt both technical and personal: what if student AI could understand context instead of starting from a blank prompt? The full story explains how we shaped the project around Maya Chen, labelized student context, multi-role agents, action cards, demo-safe behavior, and a campus-aware architecture.": "ORBIT 起源于一个既技术化又很真实的团队问题：如果学生 AI 能理解上下文，而不是每次都从空白 prompt 开始，会怎样？完整故事解释了我们如何围绕 Maya Chen、标签化学生背景、多角色智能体、行动卡片、demo 安全行为和校园感知架构来塑造这个项目。",
    "Read the Full Story": "阅读全文",
    "Continue the Showcase": "继续浏览展示页",
    "Long-form article": "长篇文章",
    "Inside the build": "构建背后",
    "When we started thinking about ORBIT, we were not only thinking about building another AI chatbot. As CS and NLP students, we wanted to build something that treats student life as a connected system...": "当我们开始构思 ORBIT 的时候，我们并不是单纯想再做一个 AI 聊天机器人。作为 CS 和 NLP 学生，我们想构建一个把学生生活当作连接系统来理解的产品...",
    "Team voice / Product + technical reflection": "团队视角 / 产品 + 技术反思",
    "Back to Showcase": "返回展示页",
    "A team-written product and technical reflection on ORBIT's motivation, design decisions, agent architecture, demo strategy, and student-success purpose.": "一篇团队视角的产品与技术反思，介绍 ORBIT 的动机、设计选择、智能体架构、demo 策略和学生成功目标。",
    "Product Overview": "产品概览",
    "A personalized multi-agent AI workspace for student life": "面向学生生活的个性化多智能体 AI 工作空间",
    "ORBIT is built on a simple product belief: students do not need one more generic chatbot. They need an assistant that knows the context they choose to share, understands campus-specific systems, coordinates specialist roles, and returns plans they can actually use.": "ORBIT 建立在一个简单的产品信念上：学生不需要又一个通用聊天机器人。他们需要的是一个能够理解他们选择分享的背景、理解校园特定系统、协调专业角色，并返回真正可执行计划的助手。",
    "Student problem": "学生问题",
    "Disconnected tools create coordination overload.": "彼此割裂的工具制造了协调负担。",
    "Assignments live in Canvas/ELMS, classes and work shifts live in Google Calendar, routes depend on Maps, course truth is split across PlanetTerp, Testudo, umd.io, and campus support offices. The information exists, but students have to integrate it while already under stress.": "作业在 Canvas/ELMS 里，课程和打工安排在 Google Calendar 里，路线依赖 Maps，课程信息又分散在 PlanetTerp、Testudo、umd.io 和校园支持办公室中。信息本身存在，但学生必须在已经有压力的情况下把这些信息整合起来。",
    "Product vision": "产品愿景",
    "ORBIT starts from a student model, not a blank prompt.": "ORBIT 从学生模型开始，而不是从空白 prompt 开始。",
    "The system uses durable labels, prior history, report state, campus context, demo/live data, role agents, runtime skills, model fallback, connected actions, and traces to transform student context into next steps.": "系统使用长期标签、历史记录、报告状态、校园上下文、demo/live 数据、角色智能体、运行时技能、模型 fallback、连接式行动和 traces，把学生背景转化成下一步行动。",
    "Why it is different": "它为什么不同",
    "It is an advisor system, not only an answer generator.": "它是一个 advisor system，而不只是答案生成器。",
    "ORBIT can move from advice to action with walking routes, calendar blocks, email-like actions, report insights, course plans, UMD resource matches, and an audit path that explains which agents and tools were used.": "ORBIT 可以把建议推进到行动，包括步行路线、日历时间块、类似邮件的操作、报告洞察、课程计划、UMD 资源匹配，以及说明使用了哪些智能体和工具的审计路径。",
    "General chatbots": "通用聊天机器人",
    "Begin mainly from the current prompt.": "主要从当前 prompt 开始。",
    "Often provide broad advice.": "通常提供较宽泛的建议。",
    "Usually use one model role for everything.": "通常用一个模型角色处理所有事情。",
    "Do not know campus data unless the student pastes it in.": "除非学生手动粘贴，否则不知道校园数据。",
    "Begins from labels, history, monitor state, and campus context.": "从标签、历史记录、监测状态和校园上下文开始。",
    "Creates concrete next actions based on deadlines, stress, route, food, and schedule.": "根据截止日期、压力、路线、饮食和日程生成具体下一步行动。",
    "Coordinates academic, stress, campus, career, logistics, and synthesis agents.": "协调学业、压力、校园、职业、生活后勤和综合回答智能体。",
    "Can fetch or mimic Canvas, Calendar, Maps, Places, PlanetTerp, Testudo/umd.io, and UMD resources.": "可以获取或模拟 Canvas、Calendar、Maps、Places、PlanetTerp、Testudo/umd.io 和 UMD 资源。",
    "Problem and Importance": "问题与重要性",
    "Students are overloaded by coordination work, not just by missing information.": "学生的负担不只是缺少信息，更是协调工作过载。",
    "ORBIT targets the everyday friction that quietly undermines student success: deadlines, hidden academic expectations, confusing campus systems, food and transport decisions, work shifts, course planning, stress, accessibility needs, and disconnected support offices.": "ORBIT 面向那些悄悄影响学生成功的日常摩擦：截止日期、隐性的学术期待、复杂的校园系统、饮食与交通决策、打工安排、课程规划、压力、无障碍需求，以及彼此分离的支持办公室。",
    "Fragmented campus systems": "碎片化的校园系统",
    "Canvas/ELMS, Google Calendar, Google Maps, Google Places, PlanetTerp, Testudo/umd.io, UMD offices, and optional community signals all answer different fragments of the same student question.": "Canvas/ELMS、Google Calendar、Google Maps、Google Places、PlanetTerp、Testudo/umd.io、UMD 办公室和可选社区信号，分别回答同一个学生问题的不同片段。",
    "Cognitive load under stress": "压力下的认知负担",
    "A student might need to decide where to eat, how to walk there, what academic task to protect, whether the plan conflicts with work, and whether the plan should be smaller because stress is already high.": "学生可能需要同时决定去哪里吃饭、怎么走过去、优先保护哪项学业任务、计划是否和打工冲突，以及在压力已经很高时计划是否应该变小。",
    "Underserved students need context-aware help": "服务不足的学生需要理解背景的帮助",
    "First-generation, international, financially stressed, accessibility-related, commuting, working, ADHD, anxiety, burnout, and language-support contexts can change what advice is respectful and realistic.": "第一代大学生、国际学生、经济压力、无障碍需求、通勤、打工、ADHD、焦虑、burnout 和语言支持等背景，都会改变什么样的建议才是尊重且现实的。",
    "Why it matters": "为什么重要",
    "ORBIT reduces the student coordination burden.": "ORBIT 减少学生的协调负担。",
    "A good student-success AI should not force students to become systems integrators. It should preserve useful context, route to the right campus-aware agent, keep recommendations safe and non-diagnostic, and translate complexity into a humane, doable next move.": "一个好的学生成功 AI 不应该逼学生成为系统集成者。它应该保留有用背景，路由到合适的校园感知智能体，保持建议安全且非诊断化，并把复杂问题转化成人性化、可执行的下一步。",
    "Demo Persona": "演示人物",
    "Maya Chen makes the product concrete.": "Maya Chen 让产品变得具体。",
    "ORBIT includes a seeded UMD student profile so the full experience can be explored without connecting a real student account. Maya's profile shows what the system feels like after it has enough context to be useful.": "ORBIT 包含一个预置的 UMD 学生画像，因此无需连接真实学生账号也能体验完整流程。Maya 的画像展示了系统在拥有足够上下文后会是什么体验。",
    "UMD student, vegan/plant-based, near IRB and McKeldin, under CMSC216 project pressure, preparing for STAT400, working later, and sensitive to stress overload.": "UMD 学生，vegan/plant-based，位置接近 IRB 和 McKeldin，面临 CMSC216 项目压力，正在准备 STAT400，之后还有打工安排，并且对压力过载较敏感。",
    "Why the seeded profile matters": "为什么预置画像重要",
    "The demo includes month-long monitor history, prior chats, generated skills, audit traces, resource cards, course planning state, and connected action examples. It lets the investor demo start inside a personalized workspace rather than a blank app that requires real credentials.": "demo 包含一个月的监测历史、过往聊天、生成技能、审计 traces、资源卡片、课程规划状态和连接式行动示例。它让投资人演示从个性化工作空间开始，而不是从需要真实凭证的空白应用开始。",
    "Before a presentation, the app can reset Maya's demo state so labels, chat history, report history, saved skill, feedback, and audit trace return to a reliable story path.": "在展示前，应用可以重置 Maya 的 demo 状态，让标签、聊天历史、报告历史、已保存技能、反馈和审计 trace 回到稳定可靠的演示路径。",
    "How We Did It": "我们如何实现",
    "Labels become routing signals for agents, tools, recommendations, and safety-aware support.": "标签成为智能体、工具、推荐和安全感知支持的路由信号。",
    "We built ORBIT around adaptive setup, durable profile labels, specialist role agents, runtime skills, connected action cards, demo-safe behavior, and an opt-in live data path.": "我们围绕自适应 setup、长期学生画像标签、专业角色智能体、运行时技能、连接式行动卡片、demo 安全行为和 opt-in live data path 构建 ORBIT。",
    "Label-to-agent workflow diagram.": "标签到智能体工作流图。",
    "Adaptive setup creates durable labels.": "自适应 setup 创建长期标签。",
    "Setup asks focused background questions about food, life stage, academic path, work, commuting, first-generation context, financial pressure, accessibility, mental health support, language, career needs, events, and life logistics.": "setup 会围绕饮食、生活阶段、学业路径、工作、通勤、第一代大学生背景、经济压力、无障碍、心理健康支持、语言、职业需求、活动和生活后勤提出聚焦的问题。",
    "Labels activate role agents.": "标签激活角色智能体。",
    "The workflow controller can activate academic planning, stress monitoring, campus resources, career strategy, life logistics, and response synthesis agents depending on the current request and student state.": "工作流控制器可以根据当前请求和学生状态，激活学业规划、压力监测、校园资源、职业策略、生活后勤和回答综合智能体。",
    "Runtime skills and tools shape the answer.": "运行时技能和工具塑造回答。",
    "Current query, selected labels, profile labels, recent history, imported data, stress band, and tool permissions create an adaptive skill for the situation.": "当前问题、选中标签、画像标签、近期历史、导入数据、压力区间和工具权限，会为当前情境生成一个自适应技能。",
    "Action cards make advice operational.": "行动卡片让建议变成操作。",
    "ORBIT can surface Google Maps route actions, calendar blocks, email drafts, report recommendations, course plans, and resource cards while keeping demo actions safely mimicked unless real OAuth is added.": "ORBIT 可以展示 Google Maps 路线操作、日历时间块、邮件草稿、报告建议、课程计划和资源卡片；除非加入真实 OAuth，否则 demo 行动会被安全模拟。",
    "One student request becomes an inspectable decision path.": "一个学生请求会变成可检查的决策路径。",
    "A student request enters the system.": "学生请求进入系统。",
    "ORBIT loads profile labels, chat history, report state, demo/live data, and relevant constraints.": "ORBIT 加载画像标签、聊天历史、报告状态、demo/live 数据和相关限制。",
    "The workflow controller decides which agents and tools should activate.": "工作流控制器决定哪些智能体和工具应该激活。",
    "Role agents analyze the request from academic, wellbeing, campus, career, and logistics perspectives.": "角色智能体从学业、身心状态、校园、职业和生活后勤角度分析请求。",
    "The runtime skill/tool router decides which action surfaces are appropriate.": "运行时技能/工具路由器决定哪些行动界面合适。",
    "Gemini is used when configured; Gemma/Ollama can be used as fallback; deterministic logic keeps the demo reliable.": "配置后会使用 Gemini；Gemma/Ollama 可作为 fallback；确定性逻辑保证 demo 可靠。",
    "The final output becomes an answer, action card, report insight, route, email draft, calendar block, course plan, or resource recommendation.": "最终输出可以成为回答、行动卡片、报告洞察、路线、邮件草稿、日历时间块、课程计划或资源推荐。",
    "Agent traces and audit logs make the path inspectable.": "智能体 traces 和审计日志让路径可检查。",
    "Product Walkthrough": "产品演示流程",
    "A complete student support flow, from account setup to explainable agent intelligence.": "从账号 setup 到可解释智能体系统的完整学生支持流程。",
    "Every screenshot from the README is included below and grouped around the product moments they demonstrate: account flow, adaptive setup, chat, demos, reports, history, UMD scenario, course planning, and the intelligence dashboard.": "README 中的每张截图都包含在下方，并按照它们展示的产品时刻分组：账号流程、自适应 setup、聊天、demo、报告、历史、UMD 场景、课程规划和智能仪表盘。",
    "01 / Signup and Login": "01 / 注册与登录",
    "Start with a normal student account flow.": "从正常的学生账号流程开始。",
    "New users can sign up and answer setup questions, while returning users can log in. Maya's seeded profile opens with labels, history, monitor data, and demo connectors already prepared so the system does not reset to zero every session.": "新用户可以注册并回答 setup 问题，老用户可以登录。Maya 的预置画像会带着标签、历史、监测数据和 demo connectors 打开，因此系统不会每次会话都从零开始。",
    "Sign up page.": "注册页面。",
    "Login page.": "登录页面。",
    "02 / Adaptive Setup": "02 / 自适应 Setup",
    "Setup questions create the first label profile.": "setup 问题创建初始标签画像。",
    "ORBIT asks focused questions instead of asking every possible question at once. Answers can create labels for food preferences, academic path, work, commuting, first-generation context, financial stress, accessibility, ADHD support, depression or anxiety support, international context, language support, course support, internships, events, and life logistics.": "ORBIT 会提出聚焦的问题，而不是一次问完所有可能的问题。回答可以创建饮食偏好、学业路径、工作、通勤、第一代大学生背景、经济压力、无障碍、ADHD 支持、抑郁或焦虑支持、国际学生背景、语言支持、课程支持、实习、活动和生活后勤等标签。",
    "Setup page.": "Setup 页面。",
    "Setup page 2.": "Setup 页面 2。",
    "03 / Chat Workspace": "03 / 聊天工作区",
    "The familiar interface hides a structured orchestration layer.": "熟悉的界面背后是结构化编排层。",
    "The chat screen shows the current student and active model path. Header controls open guide, history, report, demo path, course planner, intelligence dashboard, and settings. Underneath, each message can pass through labels, multi-agent routing, context aggregation, connected action detection, and model fallback.": "聊天界面显示当前学生和活跃模型路径。顶部控件可以打开指南、历史、报告、demo 路径、课程规划器、智能仪表盘和设置。在底层，每条消息都可能经过标签、多智能体路由、上下文聚合、连接式行动检测和模型 fallback。",
    "New chat page.": "新聊天页面。",
    "New chat page 2.": "新聊天页面 2。",
    "04 / Live Demo Videos": "04 / 实时 Demo 视频",
    "Two YouTube demos show ORBIT coordinating real student tasks.": "两个 YouTube demo 展示 ORBIT 如何协调真实学生任务。",
    "The demos are embedded responsively when the page is hosted. When the site is opened directly as a local file, the large video frame becomes a polished YouTube launch panel so it avoids local embed configuration errors.": "页面被托管时，demo 会以响应式方式嵌入。直接以本地文件打开时，大视频框会变成精致的 YouTube 启动面板，从而避免本地嵌入配置错误。",
    "Watch demo on YouTube": "在 YouTube 观看 demo",
    "Orbit - Ask for Food Place": "ORBIT - 询问用餐地点",
    "Maya asks what to do in the next 90 minutes with CMSC216 near IRB, a later work shift, and vegan food needs. ORBIT recognizes stress, uses her plant-based preference, considers location, suggests campus-relevant food, connects the decision to academic triage, and offers map or calendar actions.": "Maya 想知道在接下来 90 分钟内，面对 IRB 附近的 CMSC216、之后的打工安排和 vegan 饮食需求，应该怎么做。ORBIT 识别压力，使用她的 plant-based 偏好，考虑位置，推荐校园相关食物，把饮食决策连接到学业优先级，并提供地图或日历操作。",
    "Open fallback video link": "打开备用视频链接",
    "Orbit - Sent Email": "ORBIT - 发送邮件",
    "Maya asks ORBIT to write an email to Alex and send a calendar invite for a vegan meal at Maryland Hillel Cafe. ORBIT drafts the email, notices a calendar conflict, asks for confirmation, and uses demo notifications to mimic successful email/calendar actions safely.": "Maya 让 ORBIT 给 Alex 写邮件，并为在 Maryland Hillel Cafe 的 vegan meal 发送日历邀请。ORBIT 起草邮件，发现日历冲突，请求确认，并用 demo 通知安全模拟邮件/日历操作成功。",
    "Ask for Food Place.": "询问用餐地点。",
    "Ask for Food Place 2.": "询问用餐地点 2。",
    "Sent email demo.": "发送邮件 demo。",
    "05 / Student Report": "05 / 学生报告",
    "Analytics are translated into caring, actionable guidance.": "数据分析被转化成温和且可执行的指导。",
    "The report summarizes now, 3 days, week, month, 6 months, full year, year to date, and all-time windows. It includes happiness, stress ease, focus room, recovery room, momentum, support fit, deadline pressure, calendar density, advisor-style recommendations, next best moves, trend charts, and month-long checkpoint history.": "报告总结当前、3 天、周、月、6 个月、全年、年初至今和全部时间窗口。它包括幸福感、压力缓和、专注空间、恢复空间、动能、支持匹配度、截止日期压力、日历密度、advisor 风格建议、下一步最佳行动、趋势图和一个月检查点历史。",
    "Student report page.": "学生报告页面。",
    "Student report page 2.": "学生报告页面 2。",
    "Student report page 3.": "学生报告页面 3。",
    "06 / Chat History": "06 / 聊天历史",
    "Continuity means the student does not have to re-explain everything.": "连续性意味着学生不必反复解释所有背景。",
    "Maya's seeded history includes vegan preferences near IRB and McKeldin, CMSC216 anxiety, first-step planning, work-shift constraints, TA email help, career fair prep, food routes, Google Maps actions, and calendar/email demos.": "Maya 的预置历史包括 IRB 和 McKeldin 附近的 vegan 偏好、CMSC216 焦虑、第一步计划、打工限制、TA 邮件帮助、career fair 准备、食物路线、Google Maps 操作和日历/邮件 demo。",
    "History page.": "历史页面。",
    "07 / UMD Demo Path": "07 / UMD 演示路径",
    "The strongest investor demo shows one concrete student scenario end to end.": "最有力的投资人 demo 端到端展示一个具体学生场景。",
    "The UMD Demo Path combines Maya's profile labels, Canvas-style deadline pressure, Google Calendar-style schedule pressure, vegan and route constraints, stress alerts, next best actions, notification policy, UMD resource cards, agent execution path, and data/privacy controls.": "UMD 演示路径结合 Maya 的画像标签、Canvas 风格截止日期压力、Google Calendar 风格日程压力、vegan 和路线限制、压力提醒、下一步最佳行动、通知策略、UMD 资源卡片、智能体执行路径和数据/隐私控制。",
    "Demo path page.": "演示路径页面。",
    "Demo path page 2.": "演示路径页面 2。",
    "Demo path page 3.": "演示路径页面 3。",
    "Demo path page 4.": "演示路径页面 4。",
    "Demo path page 5.": "演示路径页面 5。",
    "Demo path page 6.": "演示路径页面 6。",
    "08 / Course Planner": "08 / 课程规划器",
    "UMD-specific course decisions become guided and realistic.": "UMD 特定的选课决策变得有指导且更现实。",
    "ORBIT can help students think about which classes fit their goals, whether the semester is too heavy, which courses are easy, moderate, or hard, which professors may fit better, and how stress, commuting, career goals, and workload should affect course choice.": "ORBIT 可以帮助学生思考哪些课程符合目标、这个学期是否过重、哪些课程简单/中等/困难、哪些教授可能更适合，以及压力、通勤、职业目标和工作量应该如何影响选课。",
    "Course planner page.": "课程规划器页面。",
    "Course planner page 2.": "课程规划器页面 2。",
    "Course planner page 3.": "课程规划器页面 3。",
    "09 / Intelligence Dashboard": "09 / 智能仪表盘",
    "The agent system is inspectable instead of opaque.": "智能体系统是可检查的，而不是黑箱。",
    "The dashboard shows demo readiness, investor tour checklist, label-driven collaboration, skill registry, saved runtime skills, feedback signal, agent audit trail, and evaluation readiness. This matters because student-support advice should be useful and auditable.": "仪表盘展示 demo 准备度、投资人演示清单、标签驱动协作、技能注册表、已保存运行时技能、反馈信号、智能体审计轨迹和评估准备度。这很重要，因为学生支持建议应该有用，也应该可审计。",
    "Intelligence dashboard page.": "智能仪表盘页面。",
    "Intelligence dashboard page 2.": "智能仪表盘页面 2。",
    "Intelligence dashboard page 3.": "智能仪表盘页面 3。",
    "Student context flows through labels, agents, skills, tools, model fallback, and action surfaces.": "学生上下文流经标签、智能体、技能、工具、模型 fallback 和行动界面。",
    "ORBIT's architecture is designed so each answer can expose agents, tools, model path, fallback reason, sources, latency, and feedback signals.": "ORBIT 的架构设计让每个回答都可以展示智能体、工具、模型路径、fallback 原因、来源、延迟和反馈信号。",
    "ORBIT system architecture diagram.": "ORBIT 系统架构图。",
    "Onboarding label ranker": "入门标签排序器",
    "Creates initial support labels from adaptive setup answers.": "从自适应 setup 回答中创建初始支持标签。",
    "Prompt router": "Prompt 路由器",
    "Uses selected and inferred labels to recommend prompt chips and skills.": "使用已选择和推断出的标签推荐 prompt chips 和技能。",
    "Support intelligence service": "支持智能服务",
    "Builds stress reports, follow-up questions, suggestions, and skill blueprints.": "构建压力报告、追问问题、建议和技能蓝图。",
    "ORBIT agent orchestrator": "ORBIT 智能体编排器",
    "Activates role agents and coordinates final response synthesis.": "激活角色智能体并协调最终回答综合。",
    "Student context aggregator": "学生上下文聚合器",
    "Loads live or demo Canvas, Calendar, Places, Routes, and course data.": "加载 live 或 demo 的 Canvas、Calendar、Places、Routes 和课程数据。",
    "UMD resource catalog": "UMD 资源目录",
    "Routes students to tutoring, accessibility, counseling, financial aid, housing, transport, safety, and more.": "把学生路由到 tutoring、无障碍、counseling、financial aid、housing、transport、safety 等资源。",
    "Course planning service": "课程规划服务",
    "Combines workload, professor/course signals, stress level, and profile labels.": "结合工作量、教授/课程信号、压力水平和画像标签。",
    "Agent audit log": "智能体审计日志",
    "Records roles, skills, tools, sources, model path, latency, and fallback reason.": "记录角色、技能、工具、来源、模型路径、延迟和 fallback 原因。",
    "Student report": "学生报告",
    "Converts monitor history into student-facing charts, ratings, and recommendations.": "把监测历史转化成面向学生的图表、评分和推荐。",
    "Data Integrations": "数据集成",
    "Campus-aware support needs official sources, student tools, and clearly labeled optional context.": "校园感知支持需要官方来源、学生工具和清晰标注的可选上下文。",
    "ORBIT separates local demo data from opt-in live integrations through the student data proxy. Official sources are treated as truth. Optional community/forum signals can add lived context but should remain contextual rather than official.": "ORBIT 通过 student data proxy 分离本地 demo 数据和 opt-in live integrations。官方来源被视为事实依据。可选社区/论坛信号可以补充真实体验背景，但应保持为上下文，而不是官方事实。",
    "Real data integration pipeline.": "真实数据集成管线。",
    "Active courses, assignment names, due dates, and academic pressure.": "活跃课程、作业名称、截止日期和学业压力。",
    "Upcoming events, schedule density, conflicts, work shifts, and planning blocks.": "即将到来的事件、日程密度、冲突、打工安排和规划时间块。",
    "Walking routes, commute constraints, map launches, and realistic movement between places.": "步行路线、通勤限制、地图打开和地点之间的现实移动。",
    "Food, study spots, housing/rent, shopping, and campus life search.": "饮食、学习地点、住房/租金、购物和校园生活搜索。",
    "Course metadata, professor reviews, and historical grade signals.": "课程元数据、教授评价和历史成绩信号。",
    "Official course, prerequisite, section, and registration structure.": "官方课程、先修课、section 和注册结构。",
    "ADS, Counseling Center, TLTC, Career Center, Health Center, Dining, Campus Pantry, ResLife, DOTS, ISSS, Writing Center, tutoring, Guided Study Sessions, Math Success, Keystone, OMSE, Student Legal Aid, Crisis Fund, Financial Aid, Dean of Students, OCRSM, NITE Ride, Paratransit, Terp Ride, Guardian App, Help Center, and related support paths.": "ADS、Counseling Center、TLTC、Career Center、Health Center、Dining、Campus Pantry、ResLife、DOTS、ISSS、Writing Center、tutoring、Guided Study Sessions、Math Success、Keystone、OMSE、Student Legal Aid、Crisis Fund、Financial Aid、Dean of Students、OCRSM、NITE Ride、Paratransit、Terp Ride、Guardian App、Help Center 以及相关支持路径。",
    "Optional community signals": "可选社区信号",
    "Reddit-style or forum context can help with lived experience around courses, housing, commuting, food, and campus life when clearly distinguished from official truth.": "Reddit 风格或论坛上下文在与官方事实明确区分时，可以帮助补充课程、住房、通勤、饮食和校园生活的真实体验。",
    "Privacy and Safety": "隐私与安全",
    "The demo is local-first, opt-in, and careful with sensitive student context.": "demo 本地优先、选择加入，并谨慎处理敏感学生背景。",
    "Local-first demo": "本地优先 demo",
    "Profile labels are stored locally, and Maya's demo mode does not require real accounts or credentials.": "画像标签存储在本地，Maya 的 demo mode 不需要真实账号或凭证。",
    "Opt-in live data": "Opt-in live data",
    "Canvas, Google, Maps, and other live connectors are designed to be added through explicit configuration and the student data proxy.": "Canvas、Google、Maps 和其他 live connectors 被设计为通过明确配置和 student data proxy 添加。",
    ".env safety": ".env 安全",
    "Real Gemini, Canvas, and Google keys stay in local `.env` and must not be committed.": "真实 Gemini、Canvas 和 Google keys 保留在本地 `.env` 中，不能提交到仓库。",
    "Demo-mode actions": "Demo-mode 行动",
    "Calendar and email actions are mimicked in demo mode unless real OAuth and permission checks are added.": "除非加入真实 OAuth 和权限检查，否则日历和邮件行动会在 demo mode 中被模拟。",
    "Approval for irreversible actions": "不可逆行动审批",
    "Irreversible actions should be blocked or require explicit user approval before execution.": "不可逆行动应被阻止，或在执行前要求用户明确批准。",
    "Non-diagnostic wellbeing support": "非诊断式身心支持",
    "Mental health content is support and resource routing, not diagnosis or therapy.": "心理健康内容是支持和资源路由，不是诊断或治疗。",
    "Technical Implementation": "技术实现",
    "Flutter app, optional student-data-proxy, and practical model fallback.": "Flutter 应用、可选 student-data-proxy 和实用模型 fallback。",
    "The README describes ORBIT as a Flutter application with a backend student-data-proxy for optional live integrations. The app separates demo mode from live mode, tries Gemini when `API_KEY` is configured, can fall back to local Gemma/Ollama, and keeps deterministic agent logic available so the demo remains reliable.": "README 将 ORBIT 描述为一个 Flutter 应用，并配有 backend student-data-proxy 用于可选 live integrations。应用分离 demo mode 和 live mode；配置 `API_KEY` 时会尝试 Gemini，也可以 fallback 到本地 Gemma/Ollama，并保留确定性智能体逻辑以保证 demo 可靠。",
    "Client": "客户端",
    "Flutter app for web, Android, and Windows desktop.": "面向 web、Android 和 Windows desktop 的 Flutter 应用。",
    "Backend": "后端",
    "Optional `backend/student-data-proxy` Node service for live student data connectors.": "用于 live student data connectors 的可选 `backend/student-data-proxy` Node 服务。",
    "Models": "模型",
    "Gemini when configured, Gemma/Ollama fallback, then deterministic logic if needed.": "配置后使用 Gemini，fallback 到 Gemma/Ollama，必要时使用确定性逻辑。",
    "Modes": "模式",
    "Seeded demo mode for presentations and opt-in live mode for external data.": "用于展示的预置 demo mode，以及用于外部数据的 opt-in live mode。",
    "Developer setup, kept accurate and out of the way.": "开发者 setup，保持准确但不喧宾夺主。",
    "These commands come from the README. The showcase itself is static and can be opened directly from `showcase/index.html`; the commands below are for running the Flutter app and optional live data proxy.": "这些命令来自 README。showcase 本身是静态页面，可以直接打开 `showcase/index.html`；下方命令用于运行 Flutter 应用和可选 live data proxy。",
    "Prerequisites": "前置要求",
    "Flutter SDK 3.4.1 or later.": "Flutter SDK 3.4.1 或更高版本。",
    "Dart, included with Flutter.": "Dart，随 Flutter 一起提供。",
    "Node.js, only for the optional Student Data Proxy.": "Node.js，仅用于可选 Student Data Proxy。",
    "Ollama, optional for local Gemma synthesis.": "Ollama，用于可选本地 Gemma synthesis。",
    "Android Studio or a physical Android device for mobile testing.": "Android Studio 或实体 Android 设备，用于移动端测试。",
    "Demo login": "Demo 登录",
    "Local environment": "本地环境",
    "Recommended `.env` template": "推荐 `.env` 模板",
    "Keep real Gemini, Canvas, and Google keys only in local `.env`. Do not commit `.env`.": "真实 Gemini、Canvas 和 Google keys 只能保存在本地 `.env` 中。不要提交 `.env`。",
    "Windows desktop": "Windows 桌面端",
    "Optional local Gemma / Ollama": "可选本地 Gemma / Ollama",
    "Optional live data proxy": "可选 live data proxy",
    "Useful proxy endpoints": "常用 proxy endpoints",
    "Canvas connect example": "Canvas 连接示例",
    "Analyze and test": "分析与测试",
    "If `flutter test` hangs on this Windows machine, prefer `dart analyze lib test` for quick verification and run focused tests from a clean PowerShell session.": "如果 `flutter test` 在这台 Windows 机器上卡住，建议用 `dart analyze lib test` 快速验证，并在干净的 PowerShell 会话中运行 focused tests。",
    "Project structure": "项目结构",
    "Local Multi-Agent System Architecture": "本地多智能体系统架构",
    "Student Data Proxy Backend Setup": "Student Data Proxy 后端设置",
    "Recommendation Skill Router Plan": "推荐技能路由计划",
    "Final Takeaway": "最终总结",
    "ORBIT proves that student AI can be personal, campus-aware, explainable, and immediately actionable.": "ORBIT 证明学生 AI 可以是个性化的、校园感知的、可解释的，并且可以立即行动。",
    "The product brings together personalized memory, multi-agent reasoning, UMD-specific data readiness, student-facing empathy, connected actions, explainability, demo reliability, and a production path for opt-in connectors.": "这个产品结合了个性化记忆、多智能体推理、UMD 特定数据准备、面向学生的共情、连接式行动、可解释性、demo 可靠性，以及 opt-in connectors 的生产化路径。",
    "Personalization depth": "个性化深度",
    "Durable labels, chat history, report state, and imported context make ORBIT remember what matters.": "长期标签、聊天历史、报告状态和导入上下文，让 ORBIT 记住真正重要的事情。",
    "Agentic architecture": "智能体架构",
    "Multi-role collaboration lets one question be evaluated across academic, wellbeing, campus, career, and life domains.": "多角色协作让一个问题可以从学业、身心状态、校园、职业和生活领域被共同评估。",
    "Real data readiness": "真实数据准备度",
    "The structure supports Canvas/ELMS, Calendar, Maps/Places, PlanetTerp, Testudo/umd.io, UMD resources, and optional community retrieval.": "结构支持 Canvas/ELMS、Calendar、Maps/Places、PlanetTerp、Testudo/umd.io、UMD 资源和可选社区检索。",
    "Actionability": "行动能力",
    "Answers can become routes, calendar blocks, email drafts, course plans, reports, and resource recommendations.": "回答可以变成路线、日历时间块、邮件草稿、课程计划、报告和资源推荐。",
    "Explainability": "可解释性",
    "Agent traces, audit logs, feedback signals, and model fallback reasons make the path inspectable.": "智能体 traces、审计日志、反馈信号和模型 fallback 原因让路径可检查。",
    "Demo reliability": "Demo 可靠性",
    "The Maya Chen fixture gives a repeatable walkthrough when OAuth, network APIs, or live credentials are unavailable.": "当 OAuth、网络 API 或 live credentials 不可用时，Maya Chen fixture 提供可重复的演示流程。",
    "Personalized multi-agent AI for student life, academic planning, and wellbeing.": "面向学生生活、学业规划和身心支持的个性化多智能体 AI。",
    "Read the source README": "阅读源 README",
    "Top": "顶部",
    "Close": "关闭"
  };
  const links = Array.from(document.querySelectorAll(".nav-links a"));
  const sections = links
    .filter((link) => link.getAttribute("href").startsWith("#"))
    .map((link) => document.querySelector(link.getAttribute("href")))
    .filter(Boolean);

  function getStoredLanguage() {
    const params = new URLSearchParams(window.location.search);
    return params.get("lang") === "zh" ? "zh" : "en";
  }

  function storeLanguage(language) {
    return language;
  }

  const originalTextNodes = new WeakMap();
  const skippedTranslationTags = new Set(["SCRIPT", "STYLE", "PRE", "CODE", "TEXTAREA", "INPUT", "IFRAME"]);

  function normalizeText(value) {
    return value.replace(/\s+/g, " ").trim();
  }

  function canTranslateTextNode(node) {
    if (!normalizeText(node.nodeValue || "")) return false;

    let parent = node.parentElement;
    while (parent) {
      if (skippedTranslationTags.has(parent.tagName)) return false;
      if (parent.hasAttribute("data-no-translate")) return false;
      parent = parent.parentElement;
    }

    return true;
  }

  function walkTextNodes(callback) {
    const walker = document.createTreeWalker(
      document.body,
      NodeFilter.SHOW_TEXT,
      {
        acceptNode(node) {
          return canTranslateTextNode(node) ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT;
        }
      }
    );

    const nodes = [];
    while (walker.nextNode()) {
      nodes.push(walker.currentNode);
    }

    nodes.forEach(callback);
  }

  function captureOriginalTextNodes() {
    walkTextNodes((node) => {
      if (!originalTextNodes.has(node)) {
        originalTextNodes.set(node, node.nodeValue);
      }
    });
  }

  function applyTextTranslations(language) {
    walkTextNodes((node) => {
      const original = originalTextNodes.get(node) || node.nodeValue;
      if (language === "en") {
        node.nodeValue = original;
        return;
      }

      const translated = textTranslations[normalizeText(original)];
      node.nodeValue = translated || original;
    });
  }

  function updateCopyButtons(language) {
    const labels = language === "zh"
      ? { copy: "复制", copied: "已复制", failed: "失败" }
      : { copy: "Copy", copied: "Copied", failed: "Failed" };

    document.querySelectorAll("[data-copy]").forEach((button) => {
      button.dataset.copyLabel = labels.copy;
      button.dataset.copiedLabel = labels.copied;
      button.dataset.failedLabel = labels.failed;
      button.textContent = labels.copy;
    });
  }

  function withLanguageParam(href, language) {
    if (href.startsWith("#") || href.startsWith("http") || href.startsWith("mailto:")) {
      return href;
    }

    const [pathAndQuery, hash = ""] = href.split("#");
    const [path, query = ""] = pathAndQuery.split("?");
    if (!path.endsWith(".html")) return href;

    const params = new URLSearchParams(query);
    if (language === "zh") {
      params.set("lang", "zh");
    } else {
      params.delete("lang");
    }

    const queryString = params.toString();
    return `${path}${queryString ? `?${queryString}` : ""}${hash ? `#${hash}` : ""}`;
  }

  function updateLocalizedLinks(language) {
    document.querySelectorAll("a[href]").forEach((link) => {
      if (!link.dataset.baseHref) {
        link.dataset.baseHref = link.getAttribute("href");
      }

      link.setAttribute("href", withLanguageParam(link.dataset.baseHref, language));
    });
  }

  function setLanguage(language) {
    const nextLanguage = language === "zh" ? "zh" : "en";
    document.body.dataset.language = nextLanguage;
    document.documentElement.lang = nextLanguage === "zh" ? "zh-CN" : "en";
    const isStoryPage = document.body.classList.contains("story-page-body");
    document.title = nextLanguage === "zh"
      ? (isStoryPage ? "ORBIT | 我们的故事" : "ORBIT | 面向学生生活的个性化多智能体 AI")
      : (isStoryPage ? "ORBIT | Our Story" : "ORBIT | Personalized Multi-Agent AI for Student Life");

    document.querySelectorAll("[data-i18n]").forEach((item) => {
      const key = item.dataset.i18n;
      const value = translations[nextLanguage] && translations[nextLanguage][key];
      if (value) {
        item.textContent = value;
      }
    });

    if (languageToggle && languageLabel) {
      languageToggle.setAttribute("aria-pressed", String(nextLanguage === "zh"));
      languageToggle.setAttribute(
        "aria-label",
        nextLanguage === "zh" ? "Switch language to English" : "Switch language to Chinese"
      );
      languageLabel.textContent = nextLanguage === "zh" ? "English" : "中文";
    }

    applyTextTranslations(nextLanguage);
    updateCopyButtons(nextLanguage);
    updateLocalizedLinks(nextLanguage);
    storeLanguage(nextLanguage);
  }

  captureOriginalTextNodes();
  setLanguage(getStoredLanguage() || "en");

  if (languageToggle) {
    languageToggle.addEventListener("click", () => {
      setLanguage(document.body.dataset.language === "zh" ? "en" : "zh");
    });
  }

  function closeNav() {
    if (!navLinks || !navToggle) return;
    navLinks.classList.remove("open");
    navToggle.setAttribute("aria-expanded", "false");
  }

  if (navToggle && navLinks) {
    navToggle.addEventListener("click", () => {
      const isOpen = navLinks.classList.toggle("open");
      navToggle.setAttribute("aria-expanded", String(isOpen));
    });

    links.forEach((link) => {
      link.addEventListener("click", closeNav);
    });
  }

  function setActiveLink(id) {
    links.forEach((link) => {
      link.classList.toggle("active", link.getAttribute("href") === `#${id}`);
    });
  }

  if ("IntersectionObserver" in window && sections.length) {
    const navObserver = new IntersectionObserver(
      (entries) => {
        const visible = entries
          .filter((entry) => entry.isIntersecting)
          .sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];

        if (visible) {
          setActiveLink(visible.target.id);
        }
      },
      {
        rootMargin: "-20% 0px -65% 0px",
        threshold: [0.1, 0.25, 0.5]
      }
    );

    sections.forEach((section) => navObserver.observe(section));
  }

  const revealItems = Array.from(document.querySelectorAll(".reveal"));

  if ("IntersectionObserver" in window) {
    const revealObserver = new IntersectionObserver(
      (entries, observer) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("visible");
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.12, rootMargin: "0px 0px -6% 0px" }
    );

    revealItems.forEach((item) => revealObserver.observe(item));
  } else {
    revealItems.forEach((item) => item.classList.add("visible"));
  }

  function updateScrollState() {
    if (backToTop) {
      backToTop.classList.toggle("visible", window.scrollY > 700);
    }

    if (header) {
      header.classList.toggle("scrolled", window.scrollY > 4);
    }
  }

  window.addEventListener("scroll", updateScrollState, { passive: true });
  updateScrollState();

  if (backToTop) {
    backToTop.addEventListener("click", () => {
      window.scrollTo({ top: 0, behavior: "smooth" });
    });
  }

  document.querySelectorAll("[data-video-frame]").forEach((frame) => {
    const iframe = frame.querySelector("iframe");
    const embedSrc = iframe ? iframe.dataset.embedSrc : "";
    const shouldEmbed = window.location.protocol !== "file:" && Boolean(embedSrc);

    if (shouldEmbed && iframe) {
      iframe.src = embedSrc;
      frame.classList.add("embed-ready");
    } else {
      frame.classList.add("launch-ready");
    }
  });

  async function copyText(text) {
    if (navigator.clipboard && window.isSecureContext) {
      await navigator.clipboard.writeText(text);
      return;
    }

    const textarea = document.createElement("textarea");
    textarea.value = text;
    textarea.setAttribute("readonly", "");
    textarea.style.position = "fixed";
    textarea.style.left = "-9999px";
    document.body.appendChild(textarea);
    textarea.select();
    document.execCommand("copy");
    textarea.remove();
  }

  document.querySelectorAll("[data-copy]").forEach((button) => {
    button.addEventListener("click", async () => {
      const code = button.parentElement ? button.parentElement.querySelector("code") : null;
      if (!code) return;

      const original = button.dataset.copyLabel || button.textContent;
      try {
        await copyText(code.textContent.trim());
        button.textContent = button.dataset.copiedLabel || "Copied";
      } catch (error) {
        button.textContent = button.dataset.failedLabel || "Failed";
      }

      window.setTimeout(() => {
        button.textContent = original;
      }, 1400);
    });
  });

  const lightbox = document.querySelector("[data-lightbox]");
  const lightboxImg = document.querySelector("[data-lightbox-img]");
  const lightboxCaption = document.querySelector("[data-lightbox-caption]");
  const lightboxClose = document.querySelector("[data-lightbox-close]");
  let lastFocused = null;

  function openLightbox(image) {
    if (!lightbox || !lightboxImg || !lightboxCaption) return;
    lastFocused = document.activeElement;
    lightboxImg.src = image.currentSrc || image.src;
    lightboxImg.alt = image.alt || "";
    const caption = image.closest("figure") ? image.closest("figure").querySelector("figcaption") : null;
    lightboxCaption.textContent = caption ? caption.textContent : image.alt || "";
    lightbox.hidden = false;
    document.body.classList.add("lightbox-open");
    if (lightboxClose) lightboxClose.focus();
  }

  function closeLightbox() {
    if (!lightbox || !lightboxImg) return;
    lightbox.hidden = true;
    lightboxImg.src = "";
    document.body.classList.remove("lightbox-open");
    if (lastFocused && typeof lastFocused.focus === "function") {
      lastFocused.focus();
    }
  }

  document.querySelectorAll(".media-card img, .poster-frame img").forEach((image) => {
    image.setAttribute("tabindex", "0");
    image.addEventListener("click", () => openLightbox(image));
    image.addEventListener("keydown", (event) => {
      if (event.key === "Enter" || event.key === " ") {
        event.preventDefault();
        openLightbox(image);
      }
    });
  });

  if (lightboxClose) {
    lightboxClose.addEventListener("click", closeLightbox);
  }

  if (lightbox) {
    lightbox.addEventListener("click", (event) => {
      if (event.target === lightbox) {
        closeLightbox();
      }
    });
  }

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
      closeNav();
      closeLightbox();
    }
  });
})();
