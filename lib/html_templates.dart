class HtmlTemplates {
static const String htmlTable = r'''
<html lang="en">

<style>
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
}
th, td {
  padding: 5px;
}
tr {
  page_break_inside: avoid;
}
</style>

<body>

<h1>Teaching Staff per Programme of Study: %programme%</h1>

<table border="1">
    <tr>
        <th rowspan="2">#</th>
        <th rowspan="2">Name</th>
        <th rowspan="2">Qualifications</th>
        <th rowspan="2">Expertise</th>
        <th rowspan="2">Programme</th>
        <th colspan="2">Module</th>
        <th rowspan="2">Periods / Week</th>
        <th rowspan="2">Total</th>
    </tr>
    <tr>
        <th>Code</th>
        <th>Name</th>
    </tr>
    %rows%
</table>

<br>

</body>
</html>''';

  static const String htmlTableRowAcademic = r'''
    <tr>
        <td rowspan="%num_of_all_modules%">%num%</td>
        <td rowspan="%num_of_all_modules%">%name%</td>
        <td rowspan="%num_of_all_modules%">%qualifications%</td>
        <td rowspan="%num_of_all_modules%">%expertise%</td>
        <td rowspan="%num_of_programme_modules%">%programme%</td>
        <td>%module_code%</td>
        <td>%module_name%</td>
        <td>%module_hours%</td>
        <td rowspan="%num_of_all_modules%">%total_hours%</td>
    </tr>''';

  static const String htmlTableRowOtherProgs = r'''
    <tr>
        <td rowspan="%num_of_other_modules%">Other Programmes</td>
        <td>%module_code%</td>
        <td>%module_name%</td>
        <td>%module_hours%</td>
    </tr>''';

  static const String htmlTableRowModule = r'''
    <tr>
        <td>%module_code%</td>
        <td>%module_name%</td>
        <td>%module_hours%</td>
    </tr>''';

  static const String htmlPageModern = r'''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Department of Computing & Mathematics</title>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;700;900&family=DM+Sans:wght@300;400;500&display=swap" rel="stylesheet" />
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    :root {
      --navy: #0d1b2a;
      --gold: #c9a84c;
      --gold-light: #e8c97a;
      --cream: #f5f0e8;
      --warm-white: #fdfaf5;
      --text: #1a1a2e;
      --muted: #6b6b80;
      --nav-h: 68px;
    }

    html { scroll-behavior: smooth; }

    body {
      font-family: 'DM Sans', sans-serif;
      background: var(--warm-white);
      color: var(--text);
      overflow-x: hidden;
    }

    /* ── NAVBAR ── */
    nav {
      position: fixed;
      top: 0; left: 0; right: 0;
      height: var(--nav-h);
      background: var(--navy);
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 48px;
      z-index: 1000;
      box-shadow: 0 2px 24px rgba(0,0,0,0.3);
    }

    .nav-brand {
      font-family: 'Playfair Display', serif;
      font-size: 1.15rem;
      color: var(--gold);
      letter-spacing: 0.02em;
      white-space: nowrap;
    }

    .nav-menus {
      display: flex;
      gap: 8px;
      list-style: none;
    }

    .nav-menus > li {
      position: relative;
    }

    .nav-menus > li > a {
      display: flex;
      align-items: center;
      gap: 6px;
      padding: 10px 18px;
      color: #c8d0e0;
      text-decoration: none;
      font-size: 0.875rem;
      font-weight: 500;
      letter-spacing: 0.06em;
      text-transform: uppercase;
      border-radius: 4px;
      transition: color 0.2s, background 0.2s;
    }

    .nav-menus > li > a::after {
      content: '▾';
      font-size: 0.75rem;
      opacity: 0.6;
      transition: transform 0.2s;
    }

    .nav-menus > li:hover > a {
      color: var(--gold-light);
      background: rgba(255,255,255,0.07);
    }

    .nav-menus > li:hover > a::after {
      transform: rotate(-180deg);
    }

    /* ── Regular Dropdown (Academics & Labs) ── */
    .dropdown {
      position: absolute;
      top: calc(100% + 8px);
      left: 0;
      background: #fff;
      border: 1px solid #e0dbd0;
      border-radius: 8px;
      box-shadow: 0 12px 40px rgba(0,0,0,0.12);
      min-width: 220px;
      opacity: 0;
      visibility: hidden;
      transform: translateY(-6px);
      transition: opacity 0.2s, transform 0.2s, visibility 0.2s;
      overflow: hidden;
    }

    .nav-menus > li:hover .dropdown {
      opacity: 1;
      visibility: visible;
      transform: translateY(0);
    }

    .dropdown a {
      display: block;
      padding: 12px 20px;
      color: var(--text);
      text-decoration: none;
      font-size: 0.88rem;
      font-weight: 400;
      border-bottom: 1px solid #f0ece4;
      transition: background 0.15s, color 0.15s, padding-left 0.15s;
    }

    .dropdown a:last-child { border-bottom: none; }

    .dropdown a:hover {
      background: var(--cream);
      color: var(--navy);
      padding-left: 28px;
    }

    .dropdown a span {
      display: inline-block;
      width: 6px; height: 6px;
      background: var(--gold);
      border-radius: 50%;
      margin-right: 10px;
      vertical-align: middle;
    }

    /* ── Mega Menu (Programmes) ── */
    .nav-menus > li.has-mega {
      position: static; /* so mega is positioned relative to the nav bar */
    }

    .mega-menu {
      position: absolute;
      top: 100%;
      right: 0;
      background: #fff;
      border-top: 3px solid var(--gold);
      box-shadow: 0 16px 48px rgba(0,0,0,0.14);
      opacity: 0;
      visibility: hidden;
      transform: translateY(-6px);
      transition: opacity 0.22s, transform 0.22s, visibility 0.22s;
      z-index: 999;
    }

    .nav-menus > li.has-mega:hover .mega-menu {
      opacity: 1;
      visibility: visible;
      transform: translateY(0);
    }

    .mega-inner {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 0;
      max-width: 1300px;
      margin: 0 auto;
      padding: 32px 48px;
    }

    .mega-col {
      padding: 0 24px;
      border-right: 1px solid #ede9e0;
    }

    .mega-col:first-child { padding-left: 0; }
    .mega-col:last-child  { padding-right: 0; border-right: none; }

    .mega-col-title {
      font-family: 'Playfair Display', serif;
      font-size: 0.78rem;
      font-weight: 700;
      letter-spacing: 0.14em;
      text-transform: uppercase;
      color: var(--gold);
      margin-bottom: 14px;
      padding-bottom: 10px;
      border-bottom: 1px solid var(--cream);
    }

    .mega-col a {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 7px 0;
      color: var(--text);
      text-decoration: none;
      font-size: 0.85rem;
      border-bottom: 1px solid #f5f2ec;
      transition: color 0.15s, gap 0.15s;
    }

    .mega-col a:last-child { border-bottom: none; }

    .mega-col a::before {
      content: '';
      display: inline-block;
      width: 5px; height: 5px;
      border-radius: 50%;
      background: var(--gold);
      opacity: 0.4;
      flex-shrink: 0;
      transition: opacity 0.15s;
    }

    .mega-col a:hover {
      color: var(--navy);
      gap: 12px;
    }

    .mega-col a:hover::before {
      opacity: 1;
    }

    .mega-footer {
      background: var(--cream);
      padding: 12px 48px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      font-size: 0.8rem;
      color: var(--muted);
    }

    .mega-footer a {
      color: var(--navy);
      text-decoration: none;
      font-weight: 600;
      font-size: 0.8rem;
      letter-spacing: 0.05em;
    }

    .mega-footer a:hover { color: var(--gold); }

    /* ── HERO ── */
    .hero {
      margin-top: var(--nav-h);
      background: var(--navy);
      padding: 80px 80px 70px;
      position: relative;
      overflow: hidden;
    }

    .hero::before {
      content: '';
      position: absolute;
      top: -60px; right: -60px;
      width: 420px; height: 420px;
      border: 80px solid rgba(201,168,76,0.08);
      border-radius: 50%;
    }

    .hero::after {
      content: '';
      position: absolute;
      bottom: -30px; right: 120px;
      width: 200px; height: 200px;
      border: 40px solid rgba(201,168,76,0.05);
      border-radius: 50%;
    }

    .hero-label {
      font-size: 0.78rem;
      letter-spacing: 0.2em;
      text-transform: uppercase;
      color: var(--gold);
      margin-bottom: 16px;
    }

    .hero h1 {
      font-family: 'Playfair Display', serif;
      font-size: clamp(2.2rem, 4vw, 3.6rem);
      font-weight: 900;
      color: #fff;
      line-height: 1.15;
      max-width: 620px;
    }

    .hero h1 em {
      font-style: normal;
      color: var(--gold);
    }

    .hero p {
      margin-top: 20px;
      color: #9ba8be;
      font-size: 1rem;
      max-width: 500px;
      line-height: 1.7;
    }

    /* ── MAIN CONTENT ── */
    main {
      max-width: 1100px;
      margin: 0 auto;
      padding: 0 48px 80px;
    }

    /* ── SECTION ── */
    .section {
      padding-top: 80px;
    }

    .section-header {
      display: flex;
      align-items: baseline;
      gap: 20px;
      margin-bottom: 40px;
      border-bottom: 2px solid var(--cream);
      padding-bottom: 20px;
    }

    .section-number {
      font-family: 'Playfair Display', serif;
      font-size: 3rem;
      font-weight: 900;
      color: var(--gold);
      opacity: 0.35;
      line-height: 1;
    }

    .section-title {
      font-family: 'Playfair Display', serif;
      font-size: 2rem;
      font-weight: 700;
      color: var(--navy);
    }

    /* ── CARDS GRID ── */
    .cards {
      display: grid;
      grid-template-columns: 1fr;
      gap: 24px;
    }

    .card {
      background: #fff;
      border: 1px solid #e8e4da;
      border-radius: 10px;
      padding: 28px 28px 24px;
      transition: transform 0.2s, box-shadow 0.2s;
      scroll-margin-top: calc(var(--nav-h) + 24px);
    }

    .card:hover {
      transform: translateY(-4px);
      box-shadow: 0 12px 32px rgba(13,27,42,0.09);
    }

    .card-tag {
      display: inline-block;
      font-size: 0.7rem;
      letter-spacing: 0.15em;
      text-transform: uppercase;
      background: var(--cream);
      color: var(--gold);
      border-radius: 4px;
      padding: 3px 10px;
      margin-bottom: 14px;
      font-weight: 600;
    }

    .card h3 {
      font-family: 'Playfair Display', serif;
      font-size: 1.2rem;
      font-weight: 700;
      color: var(--navy);
      margin-bottom: 10px;
    }

    .card p {
      font-size: 0.875rem;
      color: var(--muted);
      line-height: 1.7;
    }

    .card-meta {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      margin-top: 18px;
    }

    .badge {
      font-size: 0.72rem;
      background: #f0f4f8;
      color: #4a5568;
      border-radius: 4px;
      padding: 3px 9px;
    }

    /* Academics specific */
    .card.academic .card-avatar {
      width: 44px; height: 44px;
      background: var(--navy);
      border-radius: 50%;
      display: flex; align-items: center; justify-content: center;
      color: var(--gold);
      font-family: 'Playfair Display', serif;
      font-size: 1.1rem;
      font-weight: 700;
      margin-bottom: 14px;
    }

    /* Labs specific */
    .card.lab .lab-icon {
      font-size: 1.8rem;
      margin-bottom: 12px;
    }

    /* ── DIVIDER ── */
    .section-divider {
      height: 1px;
      background: linear-gradient(to right, var(--gold), transparent);
      margin: 20px 0 0;
      opacity: 0.3;
    }
  </style>
</head>
<body>

  %navbar%

  <!-- HERO -->
  <div class="hero">
    <h1>Timetable Genie</h1>
  </div>

  <!-- MAIN -->
  <main>

    <!-- ══ PROGRAMMES ══ -->
    <section id="programmes" class="section" style="scroll-margin-top: var(--nav-h)">
      <div class="section-header">
        <h2 class="section-title">Programmes</h2>
      </div>
      <div class="section-divider"></div>
      <br/>
      <div class="cards">

        %programmes-timetables%

        <div class="card" id="bsc-computing">
          <span class="card-tag">Undergraduate</span>
          <h3>BSc Computing</h3>
          <p>A rigorous programme covering software engineering, algorithms, data structures, networks, and artificial intelligence. Students graduate with strong analytical and practical skills ready for industry or further study.</p>
          <div class="card-meta">
            <span class="badge">3 Years</span>
            <span class="badge">180 ECTS</span>
            <span class="badge">Full-time</span>
          </div>
        </div>

        <div class="card" id="bsc-mathematics">
          <span class="card-tag">Undergraduate</span>
          <h3>BSc Mathematics</h3>
          <p>Covering pure and applied mathematics including calculus, linear algebra, probability, and mathematical modelling. Prepares students for careers in research, finance, data science, and engineering.</p>
          <div class="card-meta">
            <span class="badge">3 Years</span>
            <span class="badge">180 ECTS</span>
            <span class="badge">Full-time</span>
          </div>
        </div>

        <div class="card" id="msc-computing">
          <span class="card-tag">Postgraduate</span>
          <h3>MSc Computing</h3>
          <p>An advanced programme focusing on machine learning, distributed systems, cybersecurity, and research methods. Designed for graduates seeking to deepen their expertise or transition into research careers.</p>
          <div class="card-meta">
            <span class="badge">1.5 Years</span>
            <span class="badge">90 ECTS</span>
            <span class="badge">Full/Part-time</span>
          </div>
        </div>

      </div>
    </section>

    <!-- ══ ACADEMICS ══ -->
    <section id="academics" class="section" style="scroll-margin-top: var(--nav-h)">
      <div class="section-header">
        <span class="section-number">02</span>
        <h2 class="section-title">Academics</h2>
      </div>
      <div class="section-divider"></div>
      <br/>
      <div class="cards">

        %academics-divs%

      </div>
    </section>

    <!-- ══ LABS ══ -->
    <section id="labs" class="section" style="scroll-margin-top: var(--nav-h)">
      <div class="section-header">
        <span class="section-number">03</span>
        <h2 class="section-title">Labs</h2>
      </div>
      <div class="section-divider"></div>
      <br/>
      <div class="cards">

        <div class="card lab" id="lab-1">
          <div class="lab-icon">🖥️</div>
          <span class="card-tag">Research Lab</span>
          <h3>Lab 1 — Computing Lab</h3>
          <p>A state-of-the-art computing laboratory equipped with high-performance workstations, GPU clusters, and a dedicated development environment for software engineering and AI research projects.</p>
          <div class="card-meta">
            <span class="badge">40 Workstations</span>
            <span class="badge">GPU Cluster</span>
          </div>
        </div>

        <div class="card lab" id="lab-2">
          <div class="lab-icon">🔐</div>
          <span class="card-tag">Research Lab</span>
          <h3>Lab 2 — Security Lab</h3>
          <p>An isolated environment for cybersecurity research and practical exercises. Supports ethical hacking, penetration testing, and the development of secure systems and protocols.</p>
          <div class="card-meta">
            <span class="badge">Isolated Network</span>
            <span class="badge">24/7 Access</span>
          </div>
        </div>

        <div class="card lab" id="lab-3">
          <div class="lab-icon">📐</div>
          <span class="card-tag">Teaching Lab</span>
          <h3>Lab 3 — Mathematics Lab</h3>
          <p>A collaborative space supporting mathematical computing, statistical analysis, and modelling. Features specialised software including MATLAB, Mathematica, and R for applied research.</p>
          <div class="card-meta">
            <span class="badge">MATLAB</span>
            <span class="badge">Mathematica</span>
            <span class="badge">R</span>
          </div>
        </div>

      </div>
    </section>

  </main>

</body>
</html>
''';
}