package it.uniba.di.application;

import java.awt.BorderLayout;
import java.awt.Choice;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.EventQueue;
import java.awt.Font;
import java.awt.Graphics2D;
import java.awt.Panel;
import java.awt.Toolkit;
import java.awt.event.ItemEvent;
import java.awt.event.ItemListener;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.awt.event.MouseMotionAdapter;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.ListIterator;
import java.util.Map;
import java.util.Set;
import java.util.Spliterator;

import javax.swing.BorderFactory;
import javax.swing.DefaultListModel;
import javax.swing.JButton;
import javax.swing.JEditorPane;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JList;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JSlider;
import javax.swing.JSpinner;
import javax.swing.JTextPane;
import javax.swing.ListModel;
import javax.swing.SpinnerNumberModel;

import it.uniba.di.parser.AODVParser;
import it.uniba.di.parser.NAODVParser;
import it.uniba.di.parser.Parser;
import it.uniba.di.support.Utility;
import it.uniba.di.support.structures.ConnectivityMatrix;

public class Program extends Utility {
	private JFrame s_screen;
	private JFrame frameALA;
	private HashMap<Integer, List<connection_attempt>> pending;
	public static String fileName = null;
	private static String modelName = null;
	public static List selectedParameter = new ArrayList<>();
	public static java.awt.List progressList = new java.awt.List();
    private java.awt.List pendingList;
    
	public static Choice choice = new Choice();
	public static JScrollPane scrollPne;
	private Date executionDate;
	private static DateFormat dateFormat = new SimpleDateFormat("dd/MM/yyyy HH:mm:ss");
	public static DateFormat dateFileFormat = new SimpleDateFormat("dd_MM_yyyy_HH_mm_ss");

	private final String AODV_PATH_AND_FILENAME = "result\\AODV.asm";
	private final String NAODV_PATH_AND_FILENAME = "result\\NAODV.asm";
	private final String BNAODV_PATH_AND_FILENAME = "result\\BNAODV.asm";

	private final String AODV_MODEL_PATH_AND_FILENAME = "models\\AODV.asm";
	private final String NAODV_MODEL_PATH_AND_FILENAME = "models\\NAODV.asm";
	private final String BNAODV_MODEL_PATH_AND_FILENAME = "models\\BNAODV.asm";

	private boolean isSimulationOk;

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
					error(e);
				}
			}
		});
	}

	/**
	 * Create the application.
	 */
	public Program() {
		pending =  new HashMap<Integer,List<connection_attempt>> ();
		initialize();
	}

	/**
	 * Initialize the contents of the frame.
	 */
	private void initialize() {
		int dim_label = 20;
		frameALA = new JFrame();
		frameALA.setResizable(false);
		frameALA.setTitle("MOTION");
		Dimension dimension = Toolkit.getDefaultToolkit().getScreenSize();
		frameALA.setBounds(100, 100, 619, 614);
		int x = (int) ((dimension.getWidth() - frameALA.getWidth()) / 2);
		int y = (int) ((dimension.getHeight() - frameALA.getHeight()) / 2);
		frameALA.setBounds(x, y, 619, 553);
		frameALA.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		frameALA.getContentPane().setLayout(null);
		frameALA.getContentPane().setBackground(Color.LIGHT_GRAY);

		JLabel lblNumberOfSessions = new JLabel("Number of sessions");
		lblNumberOfSessions.setFont(new Font("Tahoma", Font.PLAIN, dim_label));
		lblNumberOfSessions.setBounds(12, 57, 193, 25);
		frameALA.getContentPane().add(lblNumberOfSessions);

		JLabel lblNumberOfBh = new JLabel("Number of blackholes");
		JSpinner fieldBlackhole = new JSpinner();
		fieldBlackhole
				.setModel(new SpinnerNumberModel(Integer.valueOf(1), Integer.valueOf(1), null, Integer.valueOf(1)));
		JLabel lblNumberOfColluder = new JLabel("Number of colluders");
		JSpinner fieldColluder = new JSpinner();
		fieldColluder
				.setModel(new SpinnerNumberModel(Integer.valueOf(1), Integer.valueOf(0), null, Integer.valueOf(1)));

		JSlider slider = new JSlider();
		JSlider slider_1 = new JSlider();
		JSlider slider_2 = new JSlider();
		slider_1.setEnabled(true);
		slider_2.setEnabled(true);
		JSpinner fieldSession = new JSpinner();
		JSpinner fieldHost = new JSpinner();
		fieldSession
				.setModel(new SpinnerNumberModel(Integer.valueOf(10), Integer.valueOf(1), null, Integer.valueOf(1)));
		fieldSession.setFont(new Font("Tahoma", Font.PLAIN, dim_label));

		JLabel lblSessionTime = new JLabel("Session duration");
		JLabel lblInitiatorProbability = new JLabel("Initiator Probability");
		JLabel lblRREPTimeout = new JLabel("RREP Timeout");
		JLabel lblSequenceNumberStep = new JLabel("Sequence number step");
		JLabel lblSequenceNumber = new JLabel("Sequence number default");
		JSpinner fieldSessionTimeout = new JSpinner();
		JSpinner fieldSeqNumStep = new JSpinner();
		JSpinner fieldSeqNumDefault = new JSpinner();
		JSpinner fieldRREPTimeout = new JSpinner();

		JButton startButton = new JButton("START");
		JButton stopButton = new JButton("STOP");
		progressList.setBounds(23, 387, 543, 138);
		frameALA.getContentPane().add(progressList);

		JScrollPane scrollPne = new JScrollPane(progressList);
		choice.addItemListener(new ItemListener() {
			public void itemStateChanged(ItemEvent arg0) {
				if (Parser.modeBNAODV()) {
					fieldBlackhole.setValue(1);
					fieldColluder.setValue(1);
					// fieldWaitingTime.setValue(5);
					fieldSeqNumStep.setValue(10);
					fieldSeqNumDefault.setValue(100);
					lblNumberOfBh.setVisible(true);
					fieldBlackhole.setVisible(true);
					lblNumberOfColluder.setVisible(true);
					fieldColluder.setVisible(true);
					// lblWaitingTime.setVisible(true);
					lblSequenceNumberStep.setVisible(true);
					lblSequenceNumber.setVisible(true);
					// fieldWaitingTime.setVisible(true);
					fieldSeqNumStep.setVisible(true);
					fieldSeqNumDefault.setVisible(true);

					startButton.setBounds(startButton.getX(), startButton.getY() + 140, startButton.getWidth(),
							startButton.getHeight());
					stopButton.setBounds(stopButton.getX(), stopButton.getY() + 140, stopButton.getWidth(),
							stopButton.getHeight());
					scrollPne.setBounds(scrollPne.getX(), scrollPne.getY() + 140, scrollPne.getWidth(),
							scrollPne.getHeight());
					frameALA.setBounds(frameALA.getX(), frameALA.getY(), frameALA.getWidth(),
							frameALA.getHeight() + 140);
				} else {
					if (lblSequenceNumberStep.isVisible()) {
						lblNumberOfBh.setVisible(false);
						fieldBlackhole.setVisible(false);
						lblNumberOfColluder.setVisible(false);
						fieldColluder.setVisible(false);
						// lblWaitingTime.setVisible(false);
						lblSequenceNumberStep.setVisible(false);
						lblSequenceNumber.setVisible(false);
						// fieldWaitingTime.setVisible(false);
						fieldSeqNumStep.setVisible(false);
						fieldSeqNumDefault.setVisible(false);

						startButton.setBounds(startButton.getX(), startButton.getY() - 140, startButton.getWidth(),
								startButton.getHeight());
						stopButton.setBounds(stopButton.getX(), stopButton.getY() - 140, stopButton.getWidth(),
								stopButton.getHeight());
						scrollPne.setBounds(scrollPne.getX(), scrollPne.getY() - 140, scrollPne.getWidth(),
								scrollPne.getHeight());
						frameALA.setBounds(frameALA.getX(), frameALA.getY(), frameALA.getWidth(),
								frameALA.getHeight() - 140);
					}
				}
			}
		});
		choice.setFont(new Font("Tahoma", Font.PLAIN, 16));
		choice.setBounds(386, 60, 214, 25);
		choice.add("AODV");
		choice.add("N-AODV");
		choice.add("BN-AODV");
		fileName = AODV_PATH_AND_FILENAME;
		modelName = AODV_MODEL_PATH_AND_FILENAME;
		frameALA.getContentPane().add(choice);

		JTextPane textPane = new JTextPane();
		JTextPane textPane_1 = new JTextPane();
		JTextPane textPane_2 = new JTextPane();
		
		
		int panelh = (550*3/4) - 90;
		int panelw = (1200/2) - 200;
		int y_pos = 5 + 15;
		int x_pos = 5;
		int x_pos2 = (1200/2) - 200 + 10;
		int y_pos2 = (550*3/4) - 80 + 35;
		

		//secondo pannello
	    s_screen = new JFrame();
		s_screen.setTitle("Connections");
		s_screen.getContentPane().setLayout(null);
		s_screen.setBounds((int) ((dimension.getWidth() - 1200) / 2),
		(0), ((1200/2) - 200) * 3 + 30,((550*3/4) - 70) * 2 + 50);
		s_screen.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		s_screen.setResizable(false);
		
	
		JLabel desc_gs = new JLabel("Mobility Model");
		desc_gs.setForeground(Color.BLACK);
		desc_gs.setFont(new Font("Tahoma", Font.PLAIN + Font.BOLD, dim_label - 7));
		desc_gs.setBounds(x_pos, y_pos - 15, 150, 15);
		desc_gs.setVisible(true);
		s_screen.getContentPane().add(desc_gs);
		Visual Gs = new Visual(panelw , panelh);
		Gs.setBounds(x_pos, y_pos, panelw , panelh);
		
		JLabel desc_s = new JLabel("Connection Attempts");
		desc_s.setForeground(Color.BLACK);
		desc_s.setFont(new Font("Tahoma", Font.PLAIN + Font.BOLD, dim_label - 7));
		desc_s.setBounds(x_pos, y_pos2 - 15, 150, 15);
		desc_s.setVisible(true);
		s_screen.getContentPane().add(desc_s);
		Visual s_panel  = new Visual(panelw, panelh);
		s_panel.setBounds(x_pos, y_pos2,panelw, panelh);
		
		JLabel desc_t = new JLabel("Successful Connection");
		desc_t.setForeground(Color.BLACK);
		desc_t.setFont(new Font("Tahoma", Font.PLAIN + Font.BOLD, dim_label - 7));
		desc_t.setBounds(x_pos2, y_pos2 - 15,150, 15);
		desc_t.setVisible(true);
		s_screen.getContentPane().add(desc_t);
		Visual t_panel  = new Visual(panelw , panelh);
		t_panel.setBounds(x_pos2 ,y_pos2, panelw , panelh);
		
		JLabel desc_q = new JLabel("Failed Connection");
		desc_q.setForeground(Color.BLACK);
		desc_q.setFont(new Font("Tahoma", Font.PLAIN + Font.BOLD, dim_label - 7));
		desc_q.setBounds(x_pos2 ,y_pos - 15,150, 15);
		desc_q.setVisible(true);
		s_screen.getContentPane().add(desc_q);
		Visual q_panel  = new Visual(panelw , panelh);
		q_panel.setBounds(x_pos2 ,y_pos,panelw, panelh);
		
		JLabel desc_pp = new JLabel("Pending Connections");
		desc_pp.setForeground(Color.BLACK);
		desc_pp.setFont(new Font("Tahoma", Font.PLAIN + Font.BOLD, dim_label - 7));
		desc_pp.setBounds(2 * x_pos2 - 5,y_pos - 15,150, 15);
		desc_pp.setVisible(true);
		s_screen.getContentPane().add(desc_pp);
		
		
		JPanel pending_panel = new JPanel(null);
        pendingList = new java.awt.List();
		pendingList.setBounds(0,0,panelw - 5, panelh);
		pendingList.setVisible(true);
	    pending_panel.add(pendingList);
	    pending_panel.setBounds(2 * x_pos2 - 5,y_pos,panelw , panelh);
	    pending_panel.setVisible(true);
	    
	    
	    
	    
		
	    s_screen.getContentPane().add(Gs);
		s_screen.getContentPane().add(s_panel);
		s_screen.getContentPane().add(t_panel);
		s_screen.getContentPane().add(q_panel);
		s_screen.getContentPane().add(pending_panel);
		
		
		 
		JLabel desc_sp = new JLabel("Moves");
		desc_sp.setForeground(Color.BLACK);
		desc_sp.setFont(new Font("Tahoma", Font.PLAIN + Font.BOLD, dim_label - 7));
		desc_sp.setBounds(2 * x_pos2 - 5,y_pos2 - 15,150, 15);
		desc_sp.setVisible(true);
		s_screen.getContentPane().add(desc_sp);
		
		scrollPne.setBounds(2 * x_pos2 - 5,y_pos2, panelw , panelh);
		scrollPne.setVisible(true);
		scrollPne.setAutoscrolls(true);
		
		s_screen.getContentPane().add(scrollPne);
		s_screen.setBackground(Color.LIGHT_GRAY);
		
		startButton.addMouseListener(new MouseAdapter() {
			@Override
			public void mousePressed(MouseEvent e) {
				new Thread(new Runnable() {
					@Override
					public void run() {
						
						s_screen.setVisible(true);
						int n_host = (int) fieldHost.getValue();
						Gs.setNumberHost(n_host);
						s_panel.setNumberHost(n_host);
						t_panel.setNumberHost(n_host);
						q_panel.setNumberHost(n_host);
						String selectedProtocol = choice.getSelectedItem();
						if ((int) fieldSession.getValue() > 0) {
							switch (selectedProtocol) {
							case "AODV":
								fileName = AODV_PATH_AND_FILENAME;
								modelName = AODV_MODEL_PATH_AND_FILENAME;
								break;
							case "N-AODV":
								fileName = NAODV_PATH_AND_FILENAME;
								modelName = NAODV_MODEL_PATH_AND_FILENAME;
								break;
							case "BN-AODV":
								fileName = BNAODV_PATH_AND_FILENAME;
								modelName = BNAODV_MODEL_PATH_AND_FILENAME;
								break;
							default:
								break;
							}
							displayInfo("Loaded model '" + modelName + "'. [" + dateFormat.format(new Date()) + "]");
							stopButton.setEnabled(true);
							startButton.setEnabled(false);
							choice.setEnabled(false);
						

							try {
								displayInfo("Creating simulation directory and sub directories...");
								String simulationTmpStr = dateFileFormat.format(new Date());
								String simulationDir = "result\\simulation_" + simulationTmpStr;
								new File(simulationDir + "\\logs").mkdirs();
								new File(simulationDir + "\\sessions").mkdirs();
								new File(simulationDir + "\\conf").mkdirs();

								File configFile = new File(simulationDir + "\\conf\\parameters.conf");
								try (FileWriter fw = new FileWriter(configFile);
										BufferedWriter bw = new BufferedWriter(fw)) {
									bw.write("Model=" + selectedProtocol);
									bw.write("\nNumber_of_sessions=" + (int) fieldSession.getValue());
									bw.write("\nNumber_of_hosts=" + (int) fieldHost.getValue());
									bw.write("\nInitial_connectivity=" + textPane_1.getText());
									bw.write("\nMobility_level=" + textPane.getText());
									bw.write("\nSession_duration=" + (int) fieldSessionTimeout.getValue());
									bw.write("\nInitiator_probability=" + textPane_2.getText());
									bw.write("\nRREP_timeout=" + fieldRREPTimeout.getValue());
								} catch (Exception ex) {
									error(ex);
								}

								displayInfo("Executing ASMETA model...");
								long start = System.currentTimeMillis();
								int max = Integer.parseInt(fieldSession.getValue().toString());
								isSimulationOk = true;
								BufferedReader br = null;
								int sessionTimeout = (int) fieldSessionTimeout.getValue();
								AODVParser aodvParser = new AODVParser();
								NAODVParser naodvParser = new NAODVParser();
								// TODO
								ConnectivityMatrix<Boolean> connectivityMatrix = new ConnectivityMatrix<Boolean>(
										Boolean.class, (int) fieldHost.getValue(), false, false);
								List<Boolean[]> cmList = new ArrayList<>();
								List<Map<String, Integer>> metricsList = new ArrayList<>();

								for (int session = 1; session <= max; session++) {
									boolean retryingMove = false;
									metricsList = new ArrayList<>();
									cmList = new ArrayList<>();
									switch (selectedProtocol) {
									case "AODV":
										AODVParser.reset();
										break;
									case "N-AODV":
										NAODVParser.reset();
										break;
									case "BN-AODV":
										// TODO
										break;
									default:
										break;
									}
									
									
									displayInfo("Now running session " + session);
									for (int moveCounter = 1; moveCounter <= sessionTimeout
											&& isSimulationOk; moveCounter++) {
										displayInfo("Now running move " + moveCounter);
										
										if (!retryingMove) {
											switch (selectedProtocol) {
											case "AODV":
												connectivityMatrix = aodvParser.modelSpecificSetup(
														(int) fieldHost.getValue(), slider.getValue(),
														slider_1.getValue(), connectivityMatrix, modelName, fileName,
														moveCounter, (int) fieldRREPTimeout.getValue(),
														slider_2.getValue());
												AODVParser.editAsmFromLog(moveCounter,
														simulationDir + "\\logs\\out.txt", fileName);
												break;
											case "N-AODV":
												connectivityMatrix = naodvParser.modelSpecificSetup(
														(int) fieldHost.getValue(), slider.getValue(),
														slider_1.getValue(), connectivityMatrix, modelName, fileName,
														moveCounter, (int) fieldRREPTimeout.getValue(),
														slider_2.getValue());
												NAODVParser.editAsmFromLog(moveCounter,
														simulationDir + "\\logs\\out.txt", fileName);
												break;
											case "BN-AODV":
												// TODO
												break;
											default:
												break;
											}
										}
										AsmetasExecutor.run(fileName, simulationDir);
										if (new File(simulationDir + "\\logs\\err.txt").exists()) {
											br = new BufferedReader(new FileReader(simulationDir + "\\logs\\err.txt"));
											if (br.readLine() != null) {
												displayInfo("ASMETA ERROR FOUND!");
												isSimulationOk = false;
											}
										} else {
											isSimulationOk = false;
										}
										if (isSimulationOk) {
											HashMap<String, Integer> metrics = null;
											HashMap<Integer, List<Integer>> ca_tot = null;
											
											
											switch (selectedProtocol) {
											case "AODV":
												metrics = aodvParser.parser(simulationDir + "\\logs\\out.txt");
												ca_tot = aodvParser.getTot_ca();
												load_ca_tot(pending,ca_tot,(int) fieldRREPTimeout.getValue());
												LinkedList <Integer> p = new LinkedList<Integer>();
												if (moveCounter > 1 && Integer
														.valueOf(metrics.get(AODVParser.RT_SIZE)) < metricsList
																.get(metricsList.size() - 1).get(AODVParser.RT_SIZE)) {
													if (!retryingMove) {
														moveCounter--;
													}
													retryingMove = true;
													displayInfo("Error on execution. Retrying ...");
													metrics = (HashMap) ((HashMap) metricsList
															.get(metricsList.size() - 1)).clone();
													aodvParser.revertMetrics(metrics);
												} else {
													retryingMove = false;
													metricsList.add((HashMap) metrics.clone());
													cmList.add(connectivityMatrix.deepCopy(Boolean.class));
												}
												break;
											case "N-AODV":
												metrics = naodvParser.parser(simulationDir + "\\logs\\out.txt");
												if (moveCounter > 1 && Integer
														.valueOf(metrics.get(AODVParser.RT_SIZE)) < metricsList
																.get(metricsList.size() - 1).get(AODVParser.RT_SIZE)) {
													if (!retryingMove) {
														moveCounter--;
													}
													retryingMove = true;
													displayInfo("Error on execution. Retrying ...");
													metrics = (HashMap) ((HashMap) metricsList
															.get(metricsList.size() - 1)).clone();
													naodvParser.revertMetrics(metrics);
												} else {
													retryingMove = false;
													metricsList.add((HashMap) metrics.clone());
													cmList.add(connectivityMatrix.deepCopy(Boolean.class));
												}
												break;
											case "BN-AODV":
												// TODO
												break;
											default:
												break;
											}
											
											Gs.loadLink(connectivityMatrix);						   
										    for (int i = 1; i < n_host + 1; i++) {
										    	int host_to;
										    	if(ca_tot.containsKey(i)) {
										    		drawConnections(s_panel,i,ca_tot.get(i),Color.YELLOW);
										    	}
										    }
										    //System.out.println(pending);
										    pendingList.removeAll();
										    processCa(t_panel,q_panel,connectivityMatrix,pending);
										    
											s_panel.repaint();
											t_panel.repaint();
											q_panel.repaint();
											Gs.repaint();
										 /* decommentare per mettere in pausa il programma dopo ogni mossa */
											
											AODVParser.showOut(simulationDir + "\\logs\\out.txt");
											
											
										}
										debug("session: " + session + " - move: " + moveCounter + " - isSimulationOk: "
												+ isSimulationOk);
									}

									if (isSimulationOk) {
										displayInfo("Writing session statistics...");
										writeSessionStatistics(simulationDir, metricsList, selectedProtocol);
										writeConnectivityMatrix(simulationDir, cmList, session);
									} else {
										break;
									}
								}
								stopButton.setEnabled(false);
								startButton.setEnabled(true);
								choice.setEnabled(true);

								executionDate = new Date();
								if (isSimulationOk) {
									displayInfo("ASMETA model executed successfully. ["
											+ dateFormat.format(executionDate) + "]");
								}
								float elapsedTime = (System.currentTimeMillis() - start) / 1000F;
								displayInfo("Elapsed time: " + elapsedTime + " sec.");

								executionDate = null;
							} catch (Exception e1) {
								error(e1);
							}
						}
					}
				}).start();
			}
		});
		
		
	
	
		
		startButton.setFont(new Font("Tahoma", Font.PLAIN, dim_label));
		startButton.setBounds(111, 463, 176, 41);
		frameALA.getContentPane().add(startButton);

		JLabel lblNumberOfHosts = new JLabel("Number of hosts");
		lblNumberOfHosts.setForeground(Color.BLACK);
		lblNumberOfHosts.setFont(new Font("Tahoma", Font.PLAIN, dim_label));
		lblNumberOfHosts.setBounds(12, 95, 155, 25);
		frameALA.getContentPane().add(lblNumberOfHosts);

		JLabel lblMobility = new JLabel("Mobility level");
		lblMobility.setForeground(Color.BLACK);
		lblMobility.setFont(new Font("Tahoma", Font.PLAIN, dim_label));
		lblMobility.setBounds(12, 260, 155, 25);
		frameALA.getContentPane().add(lblMobility);

		textPane.setBorder(BorderFactory.createLineBorder(Color.BLACK));
		textPane.setEditable(false);
		slider.addMouseMotionListener(new MouseMotionAdapter() {

			@Override
			public void mouseDragged(MouseEvent e) {
				textPane.setText(String.valueOf(slider.getValue()) + " %");
			}
		});
		slider.setBackground(Color.LIGHT_GRAY);
		slider.setFont(new Font("Tahoma", Font.PLAIN, 16));
		slider.setValue(20);
		slider.setSnapToTicks(true);
		slider.setPaintLabels(true);
		slider.setPaintTicks(true);
		slider.setLabelTable(slider.createStandardLabels(20, 0));
		slider.setBounds(196, 256, 166, 47);
		
		frameALA.getContentPane().add(slider);

		textPane_1.setEnabled(true);
		textPane_1.setBorder(BorderFactory.createLineBorder(Color.BLACK));
		textPane_1.setEditable(false);
		slider_1.addMouseMotionListener(new MouseMotionAdapter() {
			@Override
			public void mouseDragged(MouseEvent e) {
				textPane_1.setText(String.valueOf(slider_1.getValue()) + " %");
			}
		});
		slider_1.setBackground(Color.LIGHT_GRAY);
		slider_1.setFont(new Font("Tahoma", Font.PLAIN, 16));
		slider_1.setValue(20);
		slider_1.setSnapToTicks(true);
		slider_1.setPaintLabels(true);
		slider_1.setPaintTicks(true);
		slider_1.setLabelTable(slider_1.createStandardLabels(20, 0));
		slider_1.setBounds(196, 207, 166, 47);
		
		frameALA.getContentPane().add(slider_1);

		textPane_2.setEnabled(true);
		textPane_2.setBorder(BorderFactory.createLineBorder(Color.BLACK));
		textPane_2.setEditable(false);
		slider_2.addMouseMotionListener(new MouseMotionAdapter() {
			@Override
			public void mouseDragged(MouseEvent e) {
				textPane_2.setText(String.valueOf(slider_2.getValue()) + " %");
			}
		});
		slider_2.setFont(new Font("Tahoma", Font.PLAIN, 16));
		slider_2.setBackground(Color.LIGHT_GRAY);
		slider_2.setValue(20);
		slider_2.setSnapToTicks(true);
		slider_2.setPaintLabels(true);
		slider_2.setPaintTicks(true);
		slider_2.setLabelTable(slider_2.createStandardLabels(20, 0));
		slider_2.setBounds(196, 347, 166, 47);
		
		frameALA.getContentPane().add(slider_2);

		fieldHost.setModel(new SpinnerNumberModel(Integer.valueOf(5), Integer.valueOf(2), null, Integer.valueOf(1)));
		fieldHost.setFont(new Font("Tahoma", Font.PLAIN, dim_label));
		fieldHost.setBounds(289, 95, 73, 25);
		frameALA.getContentPane().add(fieldHost);
		fieldHost.setValue(5);

		fieldRREPTimeout
				.setModel(new SpinnerNumberModel(Integer.valueOf(5), Integer.valueOf(2), null, Integer.valueOf(1)));
		fieldRREPTimeout.setFont(new Font("Tahoma", Font.PLAIN, dim_label));
		fieldRREPTimeout.setBounds(289, 398, 73, 25);
		frameALA.getContentPane().add(fieldRREPTimeout);
		fieldRREPTimeout.setValue(5);

		fieldSession.setBounds(289, 57, 73, 25);
		fieldSession.setValue(10);
		frameALA.getContentPane().add(fieldSession);

		textPane.setFont(new Font("Tahoma", Font.PLAIN, dim_label));
		textPane.setText(String.valueOf(slider.getValue()) + " %");
		frameALA.getContentPane().add(textPane);

		textPane_1.setFont(new Font("Tahoma", Font.PLAIN, dim_label));
		textPane_1.setBounds(386, 207, 73, 29);
		textPane_1.setText(String.valueOf(slider_1.getValue()) + " %");
		frameALA.getContentPane().add(textPane_1);

		textPane_2.setFont(new Font("Tahoma", Font.PLAIN, dim_label));
		textPane_2.setBounds(386, 347, 73, 29);
		textPane_2.setText(String.valueOf(slider_2.getValue()) + " %");
		frameALA.getContentPane().add(textPane_2);

		stopButton.addMouseListener(new MouseAdapter() {
			@Override
			public void mousePressed(MouseEvent arg0) {
				isSimulationOk = false;
				displayInfo("Simulation has been stopped");
				stopButton.setEnabled(false);
				startButton.setEnabled(true);
			}
		});
		stopButton.setFont(new Font("Tahoma", Font.PLAIN, dim_label));
		stopButton.setBounds(299, 463, 176, 41);
		stopButton.setEnabled(false);
		frameALA.getContentPane().add(stopButton);

		lblNumberOfBh.setForeground(Color.BLACK);
		lblNumberOfBh.setFont(new Font("Tahoma", Font.PLAIN, dim_label));
		lblNumberOfBh.setBounds(12, 132, 193, 25);
		lblNumberOfBh.setVisible(false);
		frameALA.getContentPane().add(lblNumberOfBh);

		fieldBlackhole.setFont(new Font("Tahoma", Font.PLAIN, dim_label));
		fieldBlackhole.setBounds(266, 132, 73, 25);
		fieldBlackhole.setVisible(false);
		frameALA.getContentPane().add(fieldBlackhole);

		lblNumberOfColluder.setForeground(Color.BLACK);
		lblNumberOfColluder.setFont(new Font("Tahoma", Font.PLAIN, dim_label));
		lblNumberOfColluder.setBounds(12, 170, 183, 25);
		lblNumberOfColluder.setVisible(false);
		frameALA.getContentPane().add(lblNumberOfColluder);

		fieldColluder.setFont(new Font("Tahoma", Font.PLAIN, dim_label));
		fieldColluder.setBounds(266, 170, 73, 25);
		fieldColluder.setVisible(false);
		frameALA.getContentPane().add(fieldColluder);

		lblSessionTime.setForeground(Color.BLACK);
		lblSessionTime.setFont(new Font("Tahoma", Font.PLAIN, dim_label));
		lblSessionTime.setBounds(12, 304, 225, 25);
		lblSessionTime.setVisible(true);
		frameALA.getContentPane().add(lblSessionTime);

		lblInitiatorProbability.setForeground(Color.BLACK);
		
		lblInitiatorProbability.setFont(new Font("Tahoma", Font.PLAIN, dim_label));
		lblInitiatorProbability.setBounds(12, 351, 225, 25);
		lblInitiatorProbability.setVisible(true);
		frameALA.getContentPane().add(lblInitiatorProbability);

		lblRREPTimeout.setForeground(Color.BLACK);
		lblRREPTimeout.setFont(new Font("Tahoma", Font.PLAIN, dim_label));
		lblRREPTimeout.setBounds(12, 398, 225, 25);
		lblRREPTimeout.setVisible(true);
		frameALA.getContentPane().add(lblRREPTimeout);

		lblSequenceNumberStep.setForeground(Color.BLACK);
		lblSequenceNumberStep.setFont(new Font("Tahoma", Font.PLAIN, dim_label));
		lblSequenceNumberStep.setBounds(12, 390, 237, 25);
		lblSequenceNumberStep.setVisible(false);
		frameALA.getContentPane().add(lblSequenceNumberStep);

		lblSequenceNumber.setForeground(Color.BLACK);
		lblSequenceNumber.setFont(new Font("Tahoma", Font.PLAIN, dim_label));
		lblSequenceNumber.setBounds(12, 428, 237, 25);
		lblSequenceNumber.setVisible(false);
		frameALA.getContentPane().add(lblSequenceNumber);

		fieldSessionTimeout
				.setModel(new SpinnerNumberModel(Integer.valueOf(5), Integer.valueOf(1), null, Integer.valueOf(1)));
		fieldSessionTimeout.setFont(new Font("Tahoma", Font.PLAIN, dim_label));
		fieldSessionTimeout.setBounds(289, 305, 73, 25);
		fieldSessionTimeout.setValue(5);
		fieldSessionTimeout.setVisible(true);
		frameALA.getContentPane().add(fieldSessionTimeout);

		fieldSeqNumStep
				.setModel(new SpinnerNumberModel(Integer.valueOf(10), Integer.valueOf(1), null, Integer.valueOf(1)));
		fieldSeqNumStep.setFont(new Font("Tahoma", Font.PLAIN, dim_label));
		fieldSeqNumStep.setBounds(266, 390, 73, 25);
		fieldSeqNumStep.setVisible(false);
		frameALA.getContentPane().add(fieldSeqNumStep);

		fieldSeqNumDefault
				.setModel(new SpinnerNumberModel(Integer.valueOf(100), Integer.valueOf(1), null, Integer.valueOf(1)));
		fieldSeqNumDefault.setFont(new Font("Tahoma", Font.PLAIN, dim_label));
		fieldSeqNumDefault.setBounds(266, 428, 73, 25);
		fieldSeqNumDefault.setVisible(false);
		frameALA.getContentPane().add(fieldSeqNumDefault);

		JLabel lblInitialConnectivity = new JLabel("Init. Connectivity");
		lblInitialConnectivity.setForeground(Color.BLACK);
		lblInitialConnectivity.setFont(new Font("Tahoma", Font.PLAIN, dim_label));
		lblInitialConnectivity.setBounds(12, 207, 155, 25);
		lblInitialConnectivity.setEnabled(true);
		frameALA.getContentPane().add(lblInitialConnectivity);
		

		
		
		JLabel timeLabel = new JLabel();
		timeLabel.setFont(new Font("Tahoma", Font.PLAIN, dim_label));
		timeLabel.setBounds(399, 0, 201, 34);
		frameALA.getContentPane().add(timeLabel);
		new Thread(new Runnable() {
			@Override
			public void run() {
				try {
					while (!Thread.currentThread().isInterrupted()) {
						timeLabel.setText(dateFormat.format(new Date()));
						Thread.sleep(1000);
					}
				} catch (InterruptedException e) {
					error(e);
					Thread.currentThread().interrupt();
				}
			}
		}).start();

	}

	/**
	 * 
	 * @param simulationDir
	 * @param metricsList
	 * @param selectedProtocol
	 */
	private void writeSessionStatistics(String simulationDir, List<Map<String, Integer>> metricsList,
			String selectedProtocol) {
		File sessionFile = new File(
				simulationDir + "\\sessions\\session_" + dateFileFormat.format(new Date()) + ".csv");
		try (FileWriter fw = new FileWriter(sessionFile); BufferedWriter bw = new BufferedWriter(fw)) {
			bw.write("sep=,\n");
			switch (selectedProtocol) {
			case "AODV":
				bw.write(
						"CA_TOT,CA_COMPLETED,CA_SUCCESS,CA_FAILURE,RT_SIZE,INSTANTANEOUS_RT_UPDATE,RREQ_INSTANTANEOUS,RREP_INSTANTANEOUS,RERR_INSTANTANEOUS\n");
				break;
			case "N-AODV":
				bw.write(
						"CA_TOT,CA_COMPLETED,CA_SUCCESS,CA_FAILURE,RT_SIZE,INSTANTANEOUS_RT_UPDATE,RREQ_INSTANTANEOUS,RREP_INSTANTANEOUS,RERR_INSTANTANEOUS,NACK_INSTANTANEOUS\n");
				break;
			case "BN-AODV":
				// TODO
				break;
			default:
				break;
			}
		} catch (Exception ex) {
			error(ex);
		}

		try (FileWriter fw = new FileWriter(sessionFile, true); BufferedWriter bw = new BufferedWriter(fw)) {
			for (Map<String, Integer> metrics : metricsList) {
				switch (selectedProtocol) {
				case "AODV":
					bw.write(metrics.get(AODVParser.CA_TOT) + "," + metrics.get(AODVParser.CA_COMPLETED) + ","
							+ metrics.get(AODVParser.CA_SUCCESS) + "," + metrics.get(AODVParser.CA_FAILURE) + ","
							+ metrics.get(AODVParser.RT_SIZE) + "," + metrics.get(AODVParser.RT_UPDATE) + ","
							+ metrics.get(AODVParser.INST_RREQ) + "," + metrics.get(AODVParser.INST_RREP) + ","
							+ metrics.get(AODVParser.INST_RERR));
					break;
				case "N-AODV":
					bw.write(metrics.get(NAODVParser.CA_TOT) + "," + metrics.get(NAODVParser.CA_COMPLETED) + ","
							+ metrics.get(NAODVParser.CA_SUCCESS) + "," + metrics.get(NAODVParser.CA_FAILURE) + ","
							+ metrics.get(NAODVParser.RT_SIZE) + "," + metrics.get(NAODVParser.RT_UPDATE) + ","
							+ metrics.get(NAODVParser.INST_RREQ) + "," + metrics.get(NAODVParser.INST_RREP) + ","
							+ metrics.get(NAODVParser.INST_RERR) + "," + metrics.get(NAODVParser.INST_NACK));
					break;
				case "BN-AODV":
					// TODO
					break;
				default:
					break;
				}
				bw.write("\n");
			}
		} catch (Exception ex) {
			displayInfo("ERROR in writing session file data");
			error(ex);
		}
	}

	/**
	 * 
	 * @param simulationDir
	 * @param cmList
	 * @param session
	 */
	private void writeConnectivityMatrix(String simulationDir, List<Boolean[]> cmList, int session) {
		File sessionFile = new File(
				simulationDir + "\\sessions\\connectivityMatrix_" + String.format("%03d", session) + ".txt");
		try (FileWriter fw = new FileWriter(sessionFile); BufferedWriter bw = new BufferedWriter(fw)) {
			for (Boolean[] matrix : cmList) {
				for (Boolean value : matrix) {
					bw.write(value ? "1," : "0,");
				}
				bw.write("\n");
			}
		} catch (Exception ex) {
			error(ex);
			displayInfo("ERROR in creating the connectivity matrix");
		}
	}
	
	//la numerazione degli host parte da 1
	 private void processCa(Visual s,Visual f,ConnectivityMatrix cm,HashMap<Integer, List<connection_attempt>> pending) {
		    ListIterator<connection_attempt> il = null;
		    int from;
		    int to;
		   
		    LinkedList<Integer> path;
		    Set<Integer> key = pending.keySet();
			Iterator<Integer> is = key.iterator();
		    while (is.hasNext()) {
		    	from = is.next();
		    	il = pending.get(from).listIterator();
		    	while(il.hasNext()) { 
		    		connection_attempt ca = il.next();
		    		path = cm.findRoute(ca.getInit(),ca.getD());
		    		
		    		if(path != null) {
		    				s.lightsHost(ca.getInit() - 1, ca.getD() - 1);
		    				pendingList.add("(" + ca.getInit() + "," + ca.getD() + "," + ca.getTimeOut() + ") -- connected");
		    			    //System.out.println(path);
			    			drawpath(s,path,Color.GREEN);
			    			il.remove();
			    			
		    		}else {
		    			ca.decrase_t();
		    			if(ca.getTimeOut() == 0) {
		    				pendingList.add("(" + ca.getInit() + "," + ca.getD() + "," + ca.getTimeOut() + ") -- failed");
		    				f.drawConnection(ca.getInit() - 1, ca.getD() - 1,Color.RED);
		    				il.remove();
		    			}else {
		    				pendingList.add("(" + ca.getInit() + "," + ca.getD() + "," + ca.getTimeOut() + ")");
		    			}
		    		}
		    	
		    	}
		   
		}
	}
	 
	 private void drawpath(Visual s,List<Integer> to,Color c) {
		 int from;
		 int h_to;
		 
		  ListIterator<Integer> ip = to.listIterator();
		  from  = ip.next();
		  while(ip.hasNext()) {
				h_to = ip.next(); 
				s.drawConnection(from - 1, h_to - 1,c);
				from = h_to;
			} 
		 
	 }
	 
    

	 private void drawConnections(Visual s,int start,List<Integer> to,Color c){
			int host_to;
			ListIterator<Integer> it = to.listIterator();
			while(it.hasNext()) {
				host_to = it.next();
				s.drawConnection(start - 1, host_to - 1,c);
			}
		}
	 
	 private void load_ca_tot(HashMap<Integer,List<connection_attempt>> pending,HashMap<Integer, List<Integer>> ca_tot,int s_t) {
		 List<Integer> p;
		 int from;
		 int to;
		 Set<Integer> s = ca_tot.keySet();
		 Iterator<Integer> is = s.iterator();
		 while (is.hasNext()) {
			 from  = is.next();
			 p = ca_tot.get(from);
			 ListIterator<Integer> it = p.listIterator();
			 if(!pending.containsKey(from)) {pending.put(from, new LinkedList<connection_attempt> ());}
			 while(it.hasNext()) {
					 to =  it.next();
					 pending.get(from).add(new connection_attempt (from,to,s_t));
			 }	 
		     
	 }
   }
}
class connection_attempt {
	private int timeOut;
	private int initiator;
	private int destination;
	
	connection_attempt(int i,int d,int t){
		initiator = i;
		destination = d;
		timeOut = t;
	}
	public void decrase_t(){
		if(timeOut > 0) {
			timeOut--;
		}
		
	}
	public int getInit() {return initiator;}
	public int getD() {return destination;}
	public int getTimeOut() {return timeOut;}
}
