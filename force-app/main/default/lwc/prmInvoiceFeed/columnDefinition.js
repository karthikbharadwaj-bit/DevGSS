const actions = [
  { label: 'Download', name: 'download', 'iconName': 'utility:download' }
];

export default [
  { label: 'Partner Id', fieldName: 'partnerId', initialWidth: 100, hideDefaultActions: true },
  { label: 'Partner Type', fieldName: 'partnerType', initialWidth: 220, hideDefaultActions: true },
  {
    label: 'Created', fieldName: 'created', type: 'date', typeAttributes: {
      year: "numeric",
      month: "short",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit"
    },
    initialWidth: 170,
    hideDefaultActions: true
  },
  { label: 'File Name', fieldName: 'fileName', wrapText: true, hideDefaultActions: true },
  { type: 'action', typeAttributes: { rowActions: actions, menuAlignment: 'left', iconName: 'utility:block_visitor', } },
  {
    label: 'From', fieldName: 'from', type: 'date', typeAttributes: {
      year: "numeric",
      month: "short",
      day: "2-digit"
    },
    initialWidth: 100,
    hideDefaultActions: true
  },
  {
    label: 'To', fieldName: 'to', type: 'date', typeAttributes: {
      year: "numeric",
      month: "short",
      day: "2-digit"
    },
    initialWidth: 100,
    hideDefaultActions: true
  },
];