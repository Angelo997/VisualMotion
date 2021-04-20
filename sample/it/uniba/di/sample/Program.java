package it.uniba.di.sample;

import java.awt.Color;
import java.awt.Dimension;
import java.awt.EventQueue;
import java.awt.Font;
import java.awt.Toolkit;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;

import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JScrollPane;
import javax.swing.JSpinner;
import javax.swing.SpinnerNumberModel;

public class Program extends Utility {

	private JFrame frameALA;
	public static String fileName = "asmeta\\sample\\sample.asm";
	public static java.awt.List progressList = new java.awt.List();
	private static DateFormat dateFormat = new SimpleDateFormat("dd/MM/yyyy HH:mm:ss");

	/**
	 * Launch the application.
	 */
	public static void main(String[] args) {
		EventQueue.invokeLater(new Runnable() {
			public void run() {
				try {
					Program window = new Program();
					window.frameALA.setVisible(true);
				} catch (Exception e) {
					logInfo("GENERIC ERROR");
					logError(e);
				}
			}
		});
	}

	/**
	 * Create the application.
	 */
	public Program() {
		initialize();
	}

	/**
	 * Initialize the contents of the frame.
	 */
	private void initialize() {
		frameALA = new JFrame();
		frameALA.setResizable(false);
		frameALA.setTitle("SAMPLE");
		Dimension dimension = Toolkit.getDefaultToolkit().getScreenSize();
		frameALA.setBounds(100, 100, 400, 499);
		int x = (int) ((dimension.getWidth() - frameALA.getWidth()) / 2);
		int y = (int) ((dimension.getHeight() - frameALA.getHeight()) / 2);
		frameALA.setBounds(x, y, 619, 500);
		frameALA.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		frameALA.getContentPane().setLayout(null);
		JSpinner fieldRun = new JSpinner();

		JButton startButton = new JButton("START");
		progressList.setBounds(23, 387, 543, 138);
		frameALA.getContentPane().add(progressList);

		JScrollPane scrollPne = new JScrollPane(progressList);
		scrollPne.setBounds(33, 259, 543, 181);
		scrollPne.setVisible(true);
		scrollPne.setAutoscrolls(true);
		frameALA.getContentPane().add(scrollPne);

		startButton.addMouseListener(new MouseAdapter() {
			@Override
			public void mousePressed(MouseEvent e) {
				new Thread(new Runnable() {
					@Override
					public void run() {
						if ((int) fieldRun.getValue() > 0) {
							logInfo("Loaded file '" + fileName + "'. [" + dateFormat.format(new Date()) + "]");
							logInfo("Collecting information from AsmetaS...");
							try {
								logInfo("Executing sample model...");
								long start = System.currentTimeMillis();
								int maxRun = Integer.parseInt(fieldRun.getValue().toString());
								String info;
								for (int runId = 1; runId <= maxRun; runId++) {
									info = "Now running run " + runId;
									AsmetaLogParser.initializerContextPut(runId, fileName);
									Executor.execute();
									logInfo(info + " -> Moves total number "
											+ AsmetaLogParser.extractMoveNumber("asmeta\\sample\\debug.txt"));
									AsmetaLogParser.xmlBuilder(runId, maxRun, "asmeta\\sample\\debug.txt");
								}
								logInfo("Sample model executed successfully");
								float elapsedTime = (System.currentTimeMillis() - start) / 1000F;
								logInfo("Elapsed time: " + elapsedTime + " sec.");

								startButton.setEnabled(true);
							} catch (Exception e1) {
								logError(e1);
							}
						} else {
							logInfo("ERROR: All fields are required");
						}
					}

				}).start();
			}
		});
		startButton.setFont(new Font("Tahoma", Font.PLAIN, 20));
		startButton.setBounds(33, 185, 543, 41);
		frameALA.getContentPane().add(startButton);

		JLabel lblNumberOfHosts = new JLabel("Number of runs");
		lblNumberOfHosts.setForeground(Color.BLACK);
		lblNumberOfHosts.setFont(new Font("Tahoma", Font.PLAIN, 20));
		lblNumberOfHosts.setBounds(12, 95, 155, 25);
		frameALA.getContentPane().add(lblNumberOfHosts);

		fieldRun.setModel(new SpinnerNumberModel(new Integer(1), new Integer(1), null, new Integer(1)));
		fieldRun.setFont(new Font("Tahoma", Font.PLAIN, 20));
		fieldRun.setBounds(266, 95, 73, 25);
		frameALA.getContentPane().add(fieldRun);
		fieldRun.setValue(5);

		JLabel timeLabel = new JLabel();
		timeLabel.setFont(new Font("Tahoma", Font.PLAIN, 20));
		timeLabel.setBounds(399, 0, 201, 34);
		frameALA.getContentPane().add(timeLabel);
	}
}
