import 'package:flutter/material.dart';
import '../../../core/services/hive_service.dart';
import '../../../models/member_model.dart';

class ParticipantSelector extends StatefulWidget {
	final List<String> initialSelectedIds;
	final ValueChanged<List<String>> onSelectionChanged;

	const ParticipantSelector({
		super.key,
		required this.initialSelectedIds,
		required this.onSelectionChanged,
	});

	@override
	State<ParticipantSelector> createState() => _ParticipantSelectorState();
}

class _ParticipantSelectorState extends State<ParticipantSelector> {
	late List<String> _selectedIds;
	List<MemberModel> _allMembers = const [];
	List<String> _divisions = const [];
	final TextEditingController _searchController = TextEditingController();
	String _searchQuery = '';

	@override
	void initState() {
		super.initState();
		_selectedIds = List<String>.from(widget.initialSelectedIds);
		_allMembers = HiveService.members.values.toList(growable: false)
			..sort((a, b) => a.nama.compareTo(b.nama));
		_divisions = _allMembers
				.map((m) => m.divisi)
				.toSet()
				.where((div) => div.trim().isNotEmpty)
				.toList(growable: false)
			..sort();
	}

	@override
	void dispose() {
		_searchController.dispose();
		super.dispose();
	}

	bool? _getDivisionCheckboxState(String division) {
		final membersInDiv = _allMembers
				.where((m) => m.divisi == division)
				.toList(growable: false);
		if (membersInDiv.isEmpty) return false;

		var selectedCount = 0;
		for (final m in membersInDiv) {
			if (_selectedIds.contains(m.nim)) {
				selectedCount++;
			}
		}

		if (selectedCount == 0) return false;
		if (selectedCount == membersInDiv.length) return true;
		return null;
	}

	void _toggleDivision(
		String division,
		bool? newValue,
		StateSetter setModalState,
	) {
		final membersInDiv = _allMembers
				.where((m) => m.divisi == division)
				.toList(growable: false);
		setModalState(() {
			final checkAll = newValue ?? true;
			if (checkAll) {
				for (final m in membersInDiv) {
					if (!_selectedIds.contains(m.nim)) {
						_selectedIds.add(m.nim);
					}
				}
			} else {
				for (final m in membersInDiv) {
					_selectedIds.remove(m.nim);
				}
			}
		});
	}

	void _showSelectionBottomSheet() {
		_searchController.clear();
		_searchQuery = '';
		showModalBottomSheet<void>(
			context: context,
			isScrollControlled: true,
			backgroundColor: Colors.white,
			shape: const RoundedRectangleBorder(
				borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
			),
			builder: (context) {
					return StatefulBuilder(
					builder: (BuildContext context, StateSetter setModalState) {
							final filteredMembers = _searchQuery.isEmpty
									? _allMembers
									: _allMembers
											.where((m) {
												final name = m.nama.toLowerCase();
												final nim = m.nim.toLowerCase();
												final divisi = m.divisi.toLowerCase();
												return name.contains(_searchQuery) ||
													nim.contains(_searchQuery) ||
													divisi.contains(_searchQuery);
											})
											.toList(growable: false);
						return SizedBox(
							height: MediaQuery.of(context).size.height * 0.75,
							child: DefaultTabController(
								length: 2,
								child: Column(
									children: [
										Padding(
											padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
											child: Row(
												mainAxisAlignment: MainAxisAlignment.spaceBetween,
												children: [
													const Text(
														'Pilih Target Peserta',
														style: TextStyle(
															fontSize: 18,
															fontWeight: FontWeight.bold,
														),
													),
													TextButton(
														onPressed: () {
															setModalState(() {
																if (_selectedIds.length == _allMembers.length) {
																	_selectedIds.clear();
																} else {
																	_selectedIds = _allMembers
																			.map((e) => e.nim)
																			.toList(growable: false);
																}
															});
														},
														child: Text(
															_selectedIds.length == _allMembers.length
																	? 'Batal Semua'
																	: 'Pilih Semua',
														),
													),
												],
											),
										),
										const TabBar(
											labelColor: Colors.blueAccent,
											unselectedLabelColor: Colors.grey,
											indicatorColor: Colors.blueAccent,
											tabs: [
												Tab(text: 'Perorangan'),
												Tab(text: 'Berdasarkan Divisi'),
											],
										),
										Expanded(
											child: TabBarView(
												children: [
													Column(
														children: [
															Padding(
																padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
																child: TextField(
																	controller: _searchController,
																	decoration: InputDecoration(
																		hintText: 'Cari nama, NIM, atau divisi...',
																		prefixIcon: const Icon(Icons.search),
																		suffixIcon: _searchController.text.isNotEmpty
																			? IconButton(
																				icon: const Icon(Icons.close),
																				onPressed: () {
																					setModalState(() {
																						_searchController.clear();
																						_searchQuery = '';
																					});
																				},
																			)
																			: null,
																		border: OutlineInputBorder(
																			borderRadius: BorderRadius.circular(10),
																		),
																	),
																	onChanged: (value) {
																		setModalState(() {
																			_searchQuery = value.trim().toLowerCase();
																		});
																	},
																),
															),
															Expanded(
																child: ListView.builder(
																	itemCount: filteredMembers.length,
																	itemBuilder: (context, index) {
																		final member = filteredMembers[index];
																		final isSelected =
																				_selectedIds.contains(member.nim);

																		return CheckboxListTile(
																			value: isSelected,
																			activeColor: Colors.blueAccent,
																			title: Text(member.nama),
																			subtitle:
																				Text('${member.nim} • ${member.divisi}'),
																			onChanged: (bool? checked) {
																				setModalState(() {
																					if (checked == true) {
																						if (!_selectedIds.contains(member.nim)) {
																							_selectedIds.add(member.nim);
																						}
																					} else {
																						_selectedIds.remove(member.nim);
																					}
																				});
																			},
																		);
																	},
																),
															),
														],
													),
													ListView.builder(
														itemCount: _divisions.length,
														itemBuilder: (context, index) {
															final division = _divisions[index];
															final checkboxState =
																	_getDivisionCheckboxState(division);
															final membersInDiv = _allMembers
																	.where((m) => m.divisi == division)
																	.toList(growable: false);

															return ExpansionTile(
																key: PageStorageKey<String>(division),
																leading: Checkbox(
																	tristate: true,
																	value: checkboxState,
																	activeColor: Colors.blueAccent,
																	onChanged: (bool? checked) {
																		_toggleDivision(division, checked, setModalState);
																	},
																),
																title: Text(
																	division,
																	style: const TextStyle(fontWeight: FontWeight.bold),
																),
																subtitle: Text('${membersInDiv.length} anggota'),
																children: membersInDiv.map((member) {
																	final isSelected =
																			_selectedIds.contains(member.nim);
																	return Padding(
																		padding: const EdgeInsets.only(left: 48.0, right: 8.0),
																		child: CheckboxListTile(
																			value: isSelected,
																			activeColor: Colors.blueAccent,
																			dense: true,
																			title: Text(
																				member.nama,
																				style: const TextStyle(fontSize: 14),
																			),
																			subtitle: Text(
																				member.nim,
																				style: const TextStyle(fontSize: 12),
																			),
																			onChanged: (bool? checked) {
																				setModalState(() {
																					if (checked == true) {
																						if (!_selectedIds.contains(member.nim)) {
																							_selectedIds.add(member.nim);
																						}
																					} else {
																						_selectedIds.remove(member.nim);
																					}
																				});
																			},
																		),
																	);
																}).toList(growable: false),
															);
														},
													),
												],
											),
										),
										Padding(
											padding: const EdgeInsets.all(16.0),
											child: SizedBox(
												width: double.infinity,
												child: ElevatedButton(
													onPressed: () {
														widget.onSelectionChanged(
															List<String>.from(_selectedIds),
														);
														setState(() {});
														Navigator.pop(context);
													},
													style: ElevatedButton.styleFrom(
														backgroundColor: Colors.blueAccent,
														padding: const EdgeInsets.symmetric(vertical: 14),
														shape: RoundedRectangleBorder(
															borderRadius: BorderRadius.circular(8),
														),
													),
													child: const Text(
														'Simpan Pilihan',
														style: TextStyle(fontSize: 16),
													),
												),
											),
										),
									],
								),
							),
						);
					},
				);
			},
		);
	}

	@override
	Widget build(BuildContext context) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				const Text(
					'Target Peserta (Opsional)',
					style: TextStyle(
						fontSize: 14,
						fontWeight: FontWeight.bold,
						color: Colors.black87,
					),
				),
				const SizedBox(height: 8),
				InkWell(
					onTap: _showSelectionBottomSheet,
					child: Container(
						padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
						decoration: BoxDecoration(
							color: Colors.white,
							border: Border.all(color: Colors.grey[300]!),
							borderRadius: BorderRadius.circular(8),
						),
						child: Row(
							mainAxisAlignment: MainAxisAlignment.spaceBetween,
							children: [
								Text(
									_selectedIds.isEmpty
											? 'Semua Anggota (Public)'
											: '${_selectedIds.length} Peserta Terpilih (Private)',
									style: TextStyle(
										color: _selectedIds.isEmpty
												? Colors.grey[600]
												: Colors.blueAccent,
										fontWeight: _selectedIds.isEmpty
												? FontWeight.normal
												: FontWeight.bold,
									),
								),
								Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
							],
						),
					),
				),
				if (_selectedIds.isNotEmpty)
					Padding(
						padding: const EdgeInsets.only(top: 4.0),
						child: Text(
							'Catatan: Hanya peserta terpilih yang bisa memindai QR absen.',
							style: TextStyle(fontSize: 12, color: Colors.grey[500]),
						),
					),
			],
		);
	}
}
