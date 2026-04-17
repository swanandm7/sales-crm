import { downloadCSV } from './csvUtils';

export interface TemplateField {
  systemName: string;
  displayName: string;
  example: string;
  required: boolean;
}

export const LEAD_TEMPLATE_FIELDS: TemplateField[] = [
  { systemName: 'mobile_number', displayName: 'Mobile Number', example: '9876543210', required: true },
  { systemName: 'first_name', displayName: 'First Name', example: 'Rahul', required: true },
  { systemName: 'last_name', displayName: 'Last Name', example: 'Sharma', required: false },
  { systemName: 'email', displayName: 'Email', example: 'rahul.sharma@example.com', required: true },
  { systemName: 'university', displayName: 'University', example: 'Delhi University', required: false },
  { systemName: 'course', displayName: 'Course', example: 'B.Tech', required: false },
  { systemName: 'specialization', displayName: 'Specialization', example: 'Computer Science', required: false },
  { systemName: 'city', displayName: 'City', example: 'Mumbai', required: false },
  { systemName: 'country', displayName: 'Country', example: 'India', required: false },
  { systemName: 'channel', displayName: 'Channel', example: 'Google', required: true },
  { systemName: 'source', displayName: 'Source', example: 'Website', required: true },
  { systemName: 'campaign_name', displayName: 'Campaign Name', example: 'Summer Admission 2026', required: true },
];

export const generateCSVTemplate = (): string => {
  const headers = LEAD_TEMPLATE_FIELDS.map((field) => {
    if (field.required) {
      return `${field.displayName} *`;
    }
    return field.displayName;
  });

  const exampleRow = LEAD_TEMPLATE_FIELDS.map((field) => field.example);

  const instructionsRow = LEAD_TEMPLATE_FIELDS.map((field) => {
    if (field.required) {
      return 'REQUIRED';
    }
    return 'Optional';
  });

  const csvContent = [
    headers.join(','),
    exampleRow.join(','),
    instructionsRow.join(','),
  ].join('\n');

  return csvContent;
};

export const downloadLeadTemplate = (): void => {
  const content = generateCSVTemplate();
  const filename = `lead_upload_template_${new Date().toISOString().split('T')[0]}.csv`;
  downloadCSV(content, filename);
};

export const generateTemplateWithData = (data: Record<string, string>[]): string => {
  if (data.length === 0) {
    return generateCSVTemplate();
  }

  const headers = Object.keys(data[0]);
  const rows = data.map((row) => {
    return headers.map((header) => {
      const value = row[header] || '';
      return `"${value.replace(/"/g, '""')}"`;
    }).join(',');
  });

  return [headers.join(','), ...rows].join('\n');
};

export const getSystemFieldName = (displayName: string): string | null => {
  const cleanedDisplayName = displayName.replace(' *', '').trim();

  const field = LEAD_TEMPLATE_FIELDS.find(
    (f) => f.displayName.toLowerCase() === cleanedDisplayName.toLowerCase()
  );

  return field ? field.systemName : null;
};

export const getRequiredFields = (): string[] => {
  return LEAD_TEMPLATE_FIELDS.filter((field) => field.required).map((field) => field.systemName);
};

export const getAllSystemFields = (): string[] => {
  return LEAD_TEMPLATE_FIELDS.map((field) => field.systemName);
};

export const getFieldsByCategory = (): Record<string, TemplateField[]> => {
  return {
    'Required': LEAD_TEMPLATE_FIELDS.filter((f) => f.required),
    'Personal Information': LEAD_TEMPLATE_FIELDS.filter((f) =>
      ['first_name', 'last_name', 'email', 'mobile_number'].includes(f.systemName)
    ),
    'Academic Information': LEAD_TEMPLATE_FIELDS.filter((f) =>
      ['university', 'course', 'specialization'].includes(f.systemName)
    ),
    'Address Information': LEAD_TEMPLATE_FIELDS.filter((f) =>
      ['city', 'country'].includes(f.systemName)
    ),
    'Source Tracking': LEAD_TEMPLATE_FIELDS.filter((f) =>
      ['channel', 'source', 'campaign_name'].includes(f.systemName)
    ),
  };
};
