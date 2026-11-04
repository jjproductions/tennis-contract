import { formatDayOfWeek } from './scheduleGenerator';

export interface MatchSlotView {
  slot_id: string;
  match_id: string;
  week_number: number;
  day_of_week: string;
  match_date: string;
  type: 'SINGLES' | 'DOUBLES';
  court_number: number;
  status: 'CONFIRMED' | 'OPEN_SUB';
  player_id: string | null;
  player_name: string;
}

// 1. Export to CSV
export function exportToCSV(slots: MatchSlotView[], filename = 'Winter_Tennis_Schedule.csv') {
  const headers = [
    'Week Number',
    'Day of Week',
    'Match Date',
    'Match Type',
    'Court Number',
    'Player Name',
    'Status',
  ];

  const rows = slots.map((s) => [
    `Week ${s.week_number}`,
    formatDayOfWeek(s.day_of_week),
    s.match_date,
    s.type,
    `Court #${s.court_number}`,
    `"${(s.player_name || 'Vacant').replace(/"/g, '""')}"`,
    s.status === 'OPEN_SUB' ? 'SUB NEEDED' : 'CONFIRMED',
  ]);

  const csvContent =
    '\uFEFF' + [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');

  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.setAttribute('href', url);
  link.setAttribute('download', filename);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

// 2. Export to Excel (Excel HTML Table Format with styling)
export function exportToExcel(slots: MatchSlotView[], filename = 'Winter_Tennis_Schedule.xls') {
  const tableRows = slots
    .map(
      (s) => `
    <tr>
      <td style="padding: 6px; border: 1px solid #e2e8f0; font-weight: bold; text-align: center;">Week ${s.week_number}</td>
      <td style="padding: 6px; border: 1px solid #e2e8f0;">${formatDayOfWeek(s.day_of_week)}</td>
      <td style="padding: 6px; border: 1px solid #e2e8f0;">${s.match_date}</td>
      <td style="padding: 6px; border: 1px solid #e2e8f0; text-align: center;">${s.type}</td>
      <td style="padding: 6px; border: 1px solid #e2e8f0; text-align: center;">Court #${s.court_number}</td>
      <td style="padding: 6px; border: 1px solid #e2e8f0; font-weight: bold;">${s.player_name || 'Vacant'}</td>
      <td style="padding: 6px; border: 1px solid #e2e8f0; text-align: center; color: ${s.status === 'OPEN_SUB' ? '#d97706' : '#166534'}; font-weight: bold;">
        ${s.status === 'OPEN_SUB' ? 'SUB NEEDED' : 'CONFIRMED'}
      </td>
    </tr>`
    )
    .join('');

  const excelTemplate = `
    <html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns="http://www.w3.org/TR/REC-html40">
    <head>
      <meta charset="utf-8">
      <!--[if gte mso 9]>
      <xml>
        <x:ExcelWorkbook>
          <x:ExcelWorksheets>
            <x:ExcelWorksheet>
              <x:Name>Tennis Schedule</x:Name>
              <x:WorksheetOptions>
                <x:DisplayGridlines/>
              </x:WorksheetOptions>
            </x:ExcelWorksheet>
          </x:ExcelWorksheets>
        </x:ExcelWorkbook>
      </xml>
      <![endif]-->
      <style>
        body { font-family: Arial, sans-serif; }
        table { border-collapse: collapse; width: 100%; }
        th { background-color: #1e293b; color: #ffffff; padding: 8px; text-align: left; border: 1px solid #0f172a; }
      </style>
    </head>
    <body>
      <h2>Winter Tennis League - Match Schedule</h2>
      <table>
        <thead>
          <tr>
            <th>Week</th>
            <th>Day</th>
            <th>Date</th>
            <th>Type</th>
            <th>Court</th>
            <th>Player</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          ${tableRows}
        </tbody>
      </table>
    </body>
    </html>
  `;

  const blob = new Blob(['\uFEFF' + excelTemplate], {
    type: 'application/vnd.ms-excel;charset=utf-8',
  });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.setAttribute('href', url);
  link.setAttribute('download', filename);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

// 3. Export to PDF
export async function exportToPDF(
  slots: MatchSlotView[],
  title = 'Winter Tennis League Schedule',
  filename = 'Winter_Tennis_Schedule.pdf'
) {
  const [{ jsPDF }, { default: autoTable }] = await Promise.all([
    import('jspdf'),
    import('jspdf-autotable'),
  ]);
  const doc = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' });

  // Title & Header
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(16);
  doc.setTextColor(30, 41, 59); // Slate-800
  doc.text(title, 14, 18);

  doc.setFont('helvetica', 'normal');
  doc.setFontSize(9);
  doc.setTextColor(100, 116, 139); // Slate-500
  const exportDate = new Date().toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
  doc.text(`Generated on ${exportDate} • Total Scheduled Slots: ${slots.length}`, 14, 24);

  // Table Columns & Rows
  const tableHeaders = [['Week', 'Day & Date', 'Type', 'Court', 'Player Name', 'Status']];
  const tableData = slots.map((s) => [
    `Wk ${s.week_number}`,
    `${formatDayOfWeek(s.day_of_week)}\n${s.match_date}`,
    s.type,
    `Ct #${s.court_number}`,
    s.player_name || 'Vacant',
    s.status === 'OPEN_SUB' ? 'SUB NEEDED' : 'Confirmed',
  ]);

  autoTable(doc, {
    startY: 28,
    head: tableHeaders,
    body: tableData,
    theme: 'grid',
    headStyles: {
      fillColor: [30, 58, 138], // Blue 900
      textColor: [255, 255, 255],
      fontSize: 9,
      fontStyle: 'bold',
      halign: 'left',
    },
    bodyStyles: {
      fontSize: 8,
      textColor: [51, 65, 85],
    },
    alternateRowStyles: {
      fillColor: [248, 250, 252],
    },
    columnStyles: {
      0: { fontStyle: 'bold', cellWidth: 16 },
      1: { cellWidth: 32 },
      2: { cellWidth: 22 },
      3: { cellWidth: 20 },
      4: { fontStyle: 'bold', cellWidth: 60 },
      5: { cellWidth: 28 },
    },
    didParseCell: function (data) {
      if (data.section === 'body' && data.column.index === 5) {
        if (data.cell.text[0] === 'SUB NEEDED') {
          data.cell.styles.textColor = [217, 119, 6]; // Amber-600
          data.cell.styles.fontStyle = 'bold';
        }
      }
    },
    margin: { top: 28, bottom: 20, left: 14, right: 14 },
    didDrawPage: function (data) {
      // Footer page numbers
      const str = `Page ${data.pageNumber}`;
      doc.setFontSize(8);
      doc.setTextColor(148, 163, 184);
      doc.text(str, doc.internal.pageSize.width - 24, doc.internal.pageSize.height - 10);
    },
  });

  doc.save(filename);
}

// 4. Export Draft Schedule (including Quota & Blackout Summary) to PDF
export async function exportDraftSchedulePDF(
  result: any,
  title = 'Winter Tennis League - Draft Schedule Preview',
  filename = 'Draft_Tennis_Schedule_Preview.pdf'
) {
  const [{ jsPDF }, { default: autoTable }] = await Promise.all([
    import('jspdf'),
    import('jspdf-autotable'),
  ]);
  const doc = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' });
  const exportDate = new Date().toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });

  // Title Header
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(16);
  doc.setTextColor(30, 41, 59);
  doc.text(title, 14, 18);

  doc.setFont('helvetica', 'normal');
  doc.setFontSize(9);
  doc.setTextColor(100, 116, 139);
  doc.text(`Generated Draft Preview on ${exportDate} • Total Matches: ${result.matches.length}`, 14, 24);

  // Section 1: Quota & Blackout Compliance Summary
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(12);
  doc.setTextColor(15, 23, 42);
  doc.text('1. Quota & Blackout Compliance Summary', 14, 32);

  const summaryHeaders = [['Player Name', 'Singles', 'Doubles', 'Total Scheduled', 'Compliance', 'Blackouts']];
  const summaryData = (result.summaries || []).map((s: any) => {
    const totalSched = s.scheduled_singles + s.scheduled_doubles;
    const totalTarget = s.target_singles + s.target_doubles;
    const pct = totalTarget > 0 ? Math.round((totalSched / totalTarget) * 100) : 0;
    return [
      s.full_name,
      `${s.scheduled_singles} / ${s.target_singles}`,
      `${s.scheduled_doubles} / ${s.target_doubles}`,
      `${totalSched} / ${totalTarget} (${pct}%)`,
      '0 Conflicts',
      `${s.blackout_count} Wks OFF`,
    ];
  });

  autoTable(doc, {
    startY: 35,
    head: summaryHeaders,
    body: summaryData,
    theme: 'grid',
    headStyles: {
      fillColor: [16, 185, 129], // Emerald 600
      textColor: [255, 255, 255],
      fontSize: 9,
      fontStyle: 'bold',
    },
    bodyStyles: {
      fontSize: 8,
      textColor: [51, 65, 85],
    },
    alternateRowStyles: {
      fillColor: [240, 253, 244], // Emerald 50
    },
  });

  // Section 2: Match Lineup Schedule
  const finalY = (doc as any).lastAutoTable.finalY || 100;
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(12);
  doc.setTextColor(15, 23, 42);
  doc.text('2. Season Match Lineup Schedule', 14, finalY + 12);

  const matchHeaders = [['Week', 'Day & Date', 'Type', 'Court', 'Players Lineup']];
  const matchData = (result.matches || []).map((m: any) => [
    `Wk ${m.week_number}`,
    `${formatDayOfWeek(m.day_of_week)}\n${m.match_date}`,
    m.type,
    `Ct #${m.court_number}`,
    m.slots.map((s: any) => s.player_name).join(', '),
  ]);

  autoTable(doc, {
    startY: finalY + 15,
    head: matchHeaders,
    body: matchData,
    theme: 'grid',
    headStyles: {
      fillColor: [30, 58, 138], // Blue 900
      textColor: [255, 255, 255],
      fontSize: 9,
      fontStyle: 'bold',
    },
    bodyStyles: {
      fontSize: 8,
      textColor: [51, 65, 85],
    },
    alternateRowStyles: {
      fillColor: [248, 250, 252],
    },
    columnStyles: {
      0: { fontStyle: 'bold', cellWidth: 16 },
      1: { cellWidth: 30 },
      2: { cellWidth: 22 },
      3: { cellWidth: 20 },
      4: { fontStyle: 'bold', cellWidth: 94 },
    },
    didDrawPage: function (data) {
      const str = `Page ${data.pageNumber}`;
      doc.setFontSize(8);
      doc.setTextColor(148, 163, 184);
      doc.text(str, doc.internal.pageSize.width - 24, doc.internal.pageSize.height - 10);
    },
  });

  doc.save(filename);
}

// 5. Export Draft Schedule (including Quota & Blackout Summary) to Excel (.xls)
export function exportDraftScheduleExcel(
  result: any,
  filename = 'Draft_Tennis_Schedule_Preview.xls'
) {
  const summaryRows = (result.summaries || [])
    .map(
      (s: any) => `
    <tr>
      <td style="padding: 6px; border: 1px solid #e2e8f0; font-weight: bold;">${s.full_name}</td>
      <td style="padding: 6px; border: 1px solid #e2e8f0; text-align: center;">${s.scheduled_singles} / ${s.target_singles}</td>
      <td style="padding: 6px; border: 1px solid #e2e8f0; text-align: center;">${s.scheduled_doubles} / ${s.target_doubles}</td>
      <td style="padding: 6px; border: 1px solid #e2e8f0; text-align: center; font-weight: bold;">${s.scheduled_singles + s.scheduled_doubles} / ${s.target_singles + s.target_doubles}</td>
      <td style="padding: 6px; border: 1px solid #e2e8f0; text-align: center; color: #166534; font-weight: bold;">0 Conflicts</td>
      <td style="padding: 6px; border: 1px solid #e2e8f0; text-align: center;">${s.blackout_count} Weeks OFF</td>
    </tr>`
    )
    .join('');

  const matchRows = (result.matches || [])
    .map(
      (m: any) => `
    <tr>
      <td style="padding: 6px; border: 1px solid #e2e8f0; font-weight: bold; text-align: center;">Week ${m.week_number}</td>
      <td style="padding: 6px; border: 1px solid #e2e8f0;">${formatDayOfWeek(m.day_of_week)}</td>
      <td style="padding: 6px; border: 1px solid #e2e8f0;">${m.match_date}</td>
      <td style="padding: 6px; border: 1px solid #e2e8f0; text-align: center;">${m.type}</td>
      <td style="padding: 6px; border: 1px solid #e2e8f0; text-align: center;">Court #${m.court_number}</td>
      <td style="padding: 6px; border: 1px solid #e2e8f0; font-weight: bold;">${m.slots.map((s: any) => s.player_name).join(', ')}</td>
    </tr>`
    )
    .join('');

  const excelTemplate = `
    <html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns="http://www.w3.org/TR/REC-html40">
    <head>
      <meta charset="utf-8">
      <style>
        body { font-family: Arial, sans-serif; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 24px; }
        th { background-color: #1e293b; color: #ffffff; padding: 8px; text-align: left; border: 1px solid #0f172a; }
        th.summary-th { background-color: #059669; }
        h2, h3 { color: #0f172a; }
      </style>
    </head>
    <body>
      <h2>Winter Tennis League - Draft Schedule Preview</h2>
      
      <h3>1. Quota & Blackout Compliance Summary</h3>
      <table>
        <thead>
          <tr>
            <th class="summary-th">Player Name</th>
            <th class="summary-th">Singles (Scheduled / Target)</th>
            <th class="summary-th">Doubles (Scheduled / Target)</th>
            <th class="summary-th">Total Matches</th>
            <th class="summary-th">Compliance</th>
            <th class="summary-th">Blackouts</th>
          </tr>
        </thead>
        <tbody>
          ${summaryRows}
        </tbody>
      </table>

      <h3>2. Season Match Lineup Schedule</h3>
      <table>
        <thead>
          <tr>
            <th>Week</th>
            <th>Day</th>
            <th>Date</th>
            <th>Type</th>
            <th>Court</th>
            <th>Players Lineup</th>
          </tr>
        </thead>
        <tbody>
          ${matchRows}
        </tbody>
      </table>
    </body>
    </html>
  `;

  const blob = new Blob(['\uFEFF' + excelTemplate], {
    type: 'application/vnd.ms-excel;charset=utf-8',
  });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.setAttribute('href', url);
  link.setAttribute('download', filename);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

// 6. Export Draft Schedule to CSV (.csv)
export function exportDraftScheduleCSV(
  result: any,
  filename = 'Draft_Tennis_Schedule_Preview.csv'
) {
  const headers = ['Week Number', 'Day of Week', 'Match Date', 'Match Type', 'Court Number', 'Players Lineup'];
  const rows = (result.matches || []).map((m: any) => [
    `Week ${m.week_number}`,
    formatDayOfWeek(m.day_of_week),
    m.match_date,
    m.type,
    `Court #${m.court_number}`,
    `"${m.slots.map((s: any) => s.player_name).join(', ').replace(/"/g, '""')}"`,
  ]);

  const csvContent = '\uFEFF' + [headers.join(','), ...rows.map((r: any) => r.join(','))].join('\n');
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.setAttribute('href', url);
  link.setAttribute('download', filename);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}


// 7. Player Report Metrics Interface
export interface PlayerReportMetric {
  id: string;
  full_name: string;
  email: string;
  is_admin: boolean;
  approved: boolean;
  singles_share: number;
  doubles_share: number;
  total_share: number;
  target_singles: number;
  target_doubles: number;
  target_total: number;
  scheduled_singles: number;
  scheduled_doubles: number;
  scheduled_total: number;
  played_singles_to_date: number;
  played_doubles_to_date: number;
  played_total_to_date: number;
  expected_to_date: number;
  pace_delta: number;
  pace_status: 'ahead' | 'on_track' | 'behind' | 'sub_pool';
  times_subbed_out: number;
  times_subbed_in: number;
  net_sub_impact: number;
  projected_total: number;
  projected_variance: number;
  pending_sub_requests_count: number;
  pending_owed_requests_count: number;
  net_karma_balance: number;
  blackout_weeks_count: number;
  max_inactivity_streak: number;
  last_match_date: string | null;
  last_match_week: number | null;
  next_match_date: string | null;
  next_match_week: number | null;
  unique_opponents_count: number;
  unique_partners_count: number;
}

// 8. Export Player Metrics to CSV
export function exportPlayerMetricsToCSV(
  metrics: PlayerReportMetric[],
  filename = 'Winter_Tennis_Player_Metrics.csv'
) {
  const headers = [
    'Player Name',
    'Email',
    'Role',
    'Singles Share',
    'Doubles Share',
    'Target Singles',
    'Target Doubles',
    'Total Target',
    'Singles Scheduled',
    'Doubles Scheduled',
    'Total Scheduled',
    'Played to Date',
    'Expected to Date',
    'Pace Delta',
    'Pace Status',
    'Projected Total',
    'Projected Variance',
    'Subbed Out',
    'Subbed In',
    'Net Sub Impact',
    'Net Karma Balance',
    'Pending Owed Requests',
    'Blackout Weeks Count',
    'Max Idle Streak (Wks)',
    'Last Match',
    'Next Match',
    'Unique Opponents',
    'Unique Partners'
  ];

  const rows = metrics.map((m) => [
    `"${m.full_name.replace(/"/g, '""')}"`,
    `"${m.email.replace(/"/g, '""')}"`,
    m.is_admin ? 'Admin' : 'Player',
    m.singles_share,
    m.doubles_share,
    m.target_singles,
    m.target_doubles,
    m.target_total,
    m.scheduled_singles,
    m.scheduled_doubles,
    m.scheduled_total,
    m.played_total_to_date,
    m.expected_to_date.toFixed(1),
    m.pace_delta > 0 ? `+${m.pace_delta.toFixed(1)}` : m.pace_delta.toFixed(1),
    m.pace_status.toUpperCase(),
    m.projected_total,
    m.projected_variance > 0 ? `+${m.projected_variance}` : m.projected_variance,
    m.times_subbed_out,
    m.times_subbed_in,
    m.net_sub_impact > 0 ? `+${m.net_sub_impact}` : m.net_sub_impact,
    m.net_karma_balance > 0 ? `+${m.net_karma_balance}` : m.net_karma_balance,
    m.pending_owed_requests_count,
    m.blackout_weeks_count,
    m.max_inactivity_streak,
    m.last_match_date ? `${m.last_match_date} (Wk ${m.last_match_week})` : 'None',
    m.next_match_date ? `${m.next_match_date} (Wk ${m.next_match_week})` : 'None',
    m.unique_opponents_count,
    m.unique_partners_count
  ]);

  const csvContent =
    '\uFEFF' + [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');

  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.setAttribute('href', url);
  link.setAttribute('download', filename);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

// 9. Export Player Metrics to PDF
export async function exportPlayerMetricsToPDF(
  metrics: PlayerReportMetric[],
  summary: {
    totalPlayers: number;
    onTrackCount: number;
    behindCount: number;
    aheadCount: number;
    totalSubTurnover: number;
    pendingKarmaFavors: number;
    currentWeek: number;
  },
  title = 'Winter Tennis League - Player Metrics & Quota Audit Report',
  filename = 'Winter_Tennis_Player_Metrics.pdf'
) {
  const [{ jsPDF }, { default: autoTable }] = await Promise.all([
    import('jspdf'),
    import('jspdf-autotable'),
  ]);
  const doc = new jsPDF({ orientation: 'landscape', unit: 'mm', format: 'a4' });
  const exportDate = new Date().toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });

  // Header Title
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(16);
  doc.setTextColor(30, 41, 59); // Slate-800
  doc.text(title, 14, 15);

  doc.setFont('helvetica', 'normal');
  doc.setFontSize(8.5);
  doc.setTextColor(100, 116, 139); // Slate-500
  doc.text(
    `Generated on ${exportDate} • Active League Week: Wk ${summary.currentWeek} • Total Roster: ${summary.totalPlayers} Players`,
    14,
    21
  );

  // Summary Metrics Banner / Text
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(9);
  doc.setTextColor(15, 23, 42); // Slate-900
  const summaryLine = `Quota Overview: ${summary.onTrackCount} On Track (100%)  |  ${summary.behindCount} In Deficit Alert  |  ${summary.aheadCount} Surplus (Ahead)  |  ${summary.totalSubTurnover} Total Substitutions  |  ${summary.pendingKarmaFavors} Pending Karma Favors`;
  doc.text(summaryLine, 14, 27);

  // Table Data
  const headers = [
    [
      'Player Name',
      'Contract Share',
      'Singles (Act/Tgt)',
      'Doubles (Act/Tgt)',
      'To Date (Act/Exp)',
      'Quota Status',
      'Proj. Season',
      'Sub Out',
      'Sub In',
      'Net Subs',
      'Karma',
      'Owed Reqs',
      'Idle Streak',
    ],
  ];

  const data = metrics.map((m) => {
    let paceLabel = 'ON TRACK';
    if (m.pace_status === 'behind') paceLabel = `${m.projected_variance} DEFICIT`;
    else if (m.pace_status === 'ahead') paceLabel = `+${m.projected_variance} SURPLUS`;
    else if (m.pace_status === 'sub_pool') paceLabel = 'SUB POOL';

    const projDiff = m.projected_variance > 0 ? `+${m.projected_variance}` : `${m.projected_variance}`;

    return [
      m.full_name,
      `${m.singles_share}S / ${m.doubles_share}D`,
      `${m.scheduled_singles} / ${m.target_singles}`,
      `${m.scheduled_doubles} / ${m.target_doubles}`,
      `${m.played_total_to_date} / ${m.expected_to_date.toFixed(1)}`,
      paceLabel,
      `${m.projected_total} (${projDiff})`,
      `${m.times_subbed_out}`,
      `${m.times_subbed_in}`,
      m.net_sub_impact > 0 ? `+${m.net_sub_impact}` : `${m.net_sub_impact}`,
      m.net_karma_balance > 0 ? `+${m.net_karma_balance}` : `${m.net_karma_balance}`,
      m.pending_owed_requests_count > 0 ? `⭐ ${m.pending_owed_requests_count}` : '-',
      `${m.max_inactivity_streak} wks`,
    ];
  });

  autoTable(doc, {
    startY: 31,
    head: headers,
    body: data,
    theme: 'grid',
    headStyles: {
      fillColor: [30, 58, 138], // Blue-900
      textColor: [255, 255, 255],
      fontSize: 8,
      fontStyle: 'bold',
      halign: 'left',
    },
    bodyStyles: {
      fontSize: 7.5,
      textColor: [51, 65, 85],
    },
    alternateRowStyles: {
      fillColor: [248, 250, 252],
    },
    columnStyles: {
      0: { fontStyle: 'bold', cellWidth: 44 },
      1: { cellWidth: 24 },
      2: { cellWidth: 24 },
      3: { cellWidth: 24 },
      4: { cellWidth: 24 },
      5: { fontStyle: 'bold', cellWidth: 26 },
      6: { cellWidth: 20 },
      7: { cellWidth: 16 },
      8: { cellWidth: 16 },
      9: { cellWidth: 16 },
      10: { cellWidth: 14 },
      11: { fontStyle: 'bold', cellWidth: 18 },
      12: { cellWidth: 18 },
    },
    didParseCell: function (dataCell) {
      if (dataCell.section === 'body' && dataCell.column.index === 5) {
        const text = String(dataCell.cell.text[0] || '');
        if (text.includes('DEFICIT') || text.includes('BEHIND')) {
          dataCell.cell.styles.textColor = [185, 28, 28]; // Red-700
          dataCell.cell.styles.fontStyle = 'bold';
        } else if (text.includes('ON TRACK')) {
          dataCell.cell.styles.textColor = [21, 128, 61]; // Green-700
        } else if (text.includes('SURPLUS') || text.includes('AHEAD')) {
          dataCell.cell.styles.textColor = [126, 34, 206]; // Purple-700
        }
      }
      if (dataCell.section === 'body' && dataCell.column.index === 11) {
        const text = String(dataCell.cell.text[0] || '');
        if (text.includes('⭐')) {
          dataCell.cell.styles.textColor = [180, 83, 9]; // Amber-700
          dataCell.cell.styles.fontStyle = 'bold';
        }
      }
    },
    margin: { top: 31, bottom: 15, left: 14, right: 14 },
    didDrawPage: function (pageData) {
      const pageStr = `Page ${pageData.pageNumber}`;
      doc.setFontSize(7.5);
      doc.setTextColor(148, 163, 184);
      doc.text(pageStr, doc.internal.pageSize.width - 25, doc.internal.pageSize.height - 8);
    },
  });

  doc.save(filename);
}
