package it.uniba.di.application;

import java.awt.Font;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.util.List;

import javax.swing.DefaultListModel;
import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JList;

import it.uniba.di.parser.Parser;
import it.uniba.di.support.Utility;

public class ParameterSelectionDialog extends JDialog {

	public JList list;
	public JList list_1;
	public DefaultListModel listModel = new DefaultListModel();
	public DefaultListModel listModel1 = new DefaultListModel();

	/**
	 * Create the dialog.
	 */
	public ParameterSelectionDialog(List source) {
		setModal(true); // pause main program
		setTitle("Metric Selection Dialog");
		setBounds(100, 100, 690, 529);
		getContentPane().setLayout(null);
		list = new JList();
		list.setFont(new Font("Tahoma", Font.PLAIN, 16));
		list.setBounds(28, 38, 239, 422);
		list.setModel(listModel);
		getContentPane().add(list);

		for (Object object : source) {
			if (!Program.selectedParameter.contains(object)) {
				listModel.addElement(object);
			}
		}

		list_1 = new JList();
		list_1.setFont(new Font("Tahoma", Font.PLAIN, 16));
		list_1.setBounds(411, 38, 239, 422);
		list_1.setModel(listModel1);
		getContentPane().add(list_1);

		for (Object object : Program.selectedParameter) {
			listModel1.addElement(object);
		}

		JButton btnNewButton = new JButton("Add >>");
		btnNewButton.addMouseListener(new MouseAdapter() {
			@Override
			public void mousePressed(MouseEvent e) {
				List temp_list = list.getSelectedValuesList();
				for (Object object : temp_list) {
					listModel1.addElement(object);
					listModel.removeElement(object);
				}
			}
		});
		btnNewButton.setBounds(277, 137, 124, 23);
		getContentPane().add(btnNewButton);

		JButton btnNewButton_1 = new JButton("<< Remove");
		btnNewButton_1.addMouseListener(new MouseAdapter() {
			@Override
			public void mousePressed(MouseEvent e) {
				List temp_list = list_1.getSelectedValuesList();
				for (Object object : temp_list) {
					listModel.addElement(object);
					listModel1.removeElement(object);
				}
			}
		});
		btnNewButton_1.setBounds(277, 202, 124, 23);
		getContentPane().add(btnNewButton_1);

		JButton btnAddAll = new JButton("Add all >>");
		btnAddAll.addMouseListener(new MouseAdapter() {
			@Override
			public void mousePressed(MouseEvent e) {
				list.setSelectionInterval(0, listModel.getSize() - 1);
				List temp_list = list.getSelectedValuesList();
				for (Object object : temp_list) {
					listModel1.addElement(object);
					listModel.removeElement(object);
				}
			}
		});
		btnAddAll.setBounds(277, 160, 124, 23);
		getContentPane().add(btnAddAll);

		JButton button = new JButton("<< Remove all");
		button.addMouseListener(new MouseAdapter() {
			@Override
			public void mousePressed(MouseEvent e) {
				list_1.setSelectionInterval(0, listModel1.getSize() - 1);
				List temp_list = list_1.getSelectedValuesList();
				for (Object object : temp_list) {
					listModel.addElement(object);
					listModel1.removeElement(object);
				}
			}
		});
		button.setBounds(277, 225, 124, 23);
		getContentPane().add(button);

		JButton btnConfirm = new JButton("CONFIRM");
		btnConfirm.addMouseListener(new MouseAdapter() {
			@Override
			public void mousePressed(MouseEvent e) {
				Program.selectedParameter.clear();
				if (listModel1.getSize() > 0) {
					list_1.setSelectionInterval(0, listModel1.getSize() - 1);
					List temp_list = list_1.getSelectedValuesList();
					for (Object object : temp_list) {
						Program.selectedParameter.add(object);
					}
				} else {
					/*
					 * default: all metrics will be imported
					 */
					for (Object object : source) {
						Program.selectedParameter.add(object);
					}
				}
				setModal(false); // resume main program
				dispose();
			}
		});
		btnConfirm.setFont(new Font("Tahoma", Font.PLAIN, 14));
		btnConfirm.setBounds(277, 286, 124, 23);
		getContentPane().add(btnConfirm);

	}

	public static void open(String resultFilePath) {
		try {
			ParameterSelectionDialog dialog = new ParameterSelectionDialog(Parser.getList(resultFilePath));
			dialog.setDefaultCloseOperation(JDialog.DISPOSE_ON_CLOSE);
			dialog.setVisible(true);
		} catch (Exception ex) {
			Utility.displayInfo("GENERIC ERROR");
			//Utility.logError(ex);
		}
	}
}
