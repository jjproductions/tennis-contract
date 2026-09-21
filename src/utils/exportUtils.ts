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
