package it.uniba.di.parser;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import it.uniba.di.support.MobilityModel;
import it.uniba.di.support.Utility;
import it.uniba.di.support.structures.ConnectivityMatrix;

/**
 *
 * @author Marco Pinto
 */
public class AODVParser extends Utility {
	private static HashMap<String, Integer> metricsMap = new HashMap<>();
	private static List<String> uniqueMessage = new ArrayList<>();
	private static List<String> uniqueRoutingTables = new ArrayList<>();

	public static final String CA_TOT = "ca_tot";
	public static final String CA_COMPLETED = "ca_completed";
	public static final String CA_SUCCESS = "ca_success";
	public static final String CA_FAILURE = "ca_failure";
	public static final String RT_SIZE = "rt_size";
	public static final String RT_UPDATE = "rt_update";
	public static final String INST_RREQ = "inst_rreq";
	public static final String INST_RREP = "inst_rrep";
	public static final String INST_RERR = "inst_rerr";

	static {
		metricsMap.put(CA_TOT, 0);
		metricsMap.put(CA_COMPLETED, 0);
		metricsMap.put(CA_SUCCESS, 0);
		metricsMap.put(CA_FAILURE, 0);
		metricsMap.put(RT_SIZE, 0);
		metricsMap.put(RT_UPDATE, 0);
		metricsMap.put(INST_RREQ, 0);
		metricsMap.put(INST_RREP, 0);
		metricsMap.put(INST_RERR, 0);
	}
	public static final String ASMETA_EQUAL = ":=";
	public static final String ASMETA_VARIABLE = "$_";
	public static final String ASMETA_PARALLEL_BLOCK_BEGIN = "par";
	public static final String ASMETA_PARALLEL_BLOCK_END = "endpar";

	public static final String NEW_LINE = System.getProperty("line.separator");
	public static final String TAB_3 = "\t\t\t";
	public static final String TAB_4 = "\t\t\t\t";
	public static final String TAB_5 = "\t\t\t\t\t";

	public static final String HOST_CODE = "/* HOSTS */";
	public static final String MESSAGES_CODE = "/* MESSAGES */";
	public static final String MOBILITY_CODE = "/* MOBILITY MODEL */";
	public static final String PREDICATE_CODE = "/* PREDICATE_INIT */";
	public static final String ROUTING_CODE = "/* ROUTING_TABLE */";
	public static final String START_PAR = "/* START PAR */";
	public static final String END_PAR = "/* END PAR */";
	public static final String START_SEQ_MAIN = "/* START SEQ MAIN */";
	public static final String END_SEQ_MAIN = "/* END SEQ MAIN */";
	public static final String REQ_TIMEOUT = "/* REQ TIMEOUT */";
	public static final String COMM_PROBABILITY = "/* COMM PROBABILITY */";

	private static Integer messageLines = 0;
	private static Integer routingLines = 0;
	private static Integer predicateLines = 0;
	private static Boolean atleastOneLink = false;

	/**
	 * 
	 * @param fieldHost
	 * @param fieldMobility
	 * @param fieldInitMobility
	 * @param cm
	 * @param modelPath
	 * @param asmPath
	 * @param moveCounter
	 * @param timeout
	 * @param commProbability
	 * @return
	 */
	public ConnectivityMatrix<Boolean> modelSpecificSetup(int fieldHost, int fieldMobility, int fieldInitMobility,
			ConnectivityMatrix<Boolean> cm, String modelPath, String asmPath, int moveCounter, int timeout,
			int commProbability) {
		atleastOneLink = false;
		StringBuilder stringBuilder = new StringBuilder();
		if (cm == null) {
			cm = new ConnectivityMatrix<>(Boolean.class, fieldHost, false, false);
		}
		try (FileReader in = new FileReader(modelPath); BufferedReader br = new BufferedReader(in)) {
			String line;
			while ((line = br.readLine()) != null) {

				if (line.contains(MOBILITY_CODE)) {
					if (moveCounter == 1) {
						String mobilityLine = MobilityModel.initConnectivity(fieldInitMobility, fieldHost, cm);
						stringBuilder.append(mobilityLine);
						if (!mobilityLine.isEmpty())
							atleastOneLink = true;
						stringBuilder.append(NEW_LINE);
					} else {
						String mobilityLine = MobilityModel.mobilitySetup(fieldMobility, fieldHost, cm);
						stringBuilder.append(mobilityLine);
						if (!mobilityLine.isEmpty())
							atleastOneLink = true;
						stringBuilder.append(NEW_LINE);
					}
				} else if (line.contains(HOST_CODE)) {
					for (int i = 1; i <= fieldHost; i++) {
						stringBuilder.append("\tstatic host" + i + ": Agent");
						stringBuilder.append(NEW_LINE);
					}
				} else if (line.contains(REQ_TIMEOUT)) {
					stringBuilder.append(line.replace(REQ_TIMEOUT, String.valueOf(timeout)));
					stringBuilder.append(NEW_LINE);
				} else if (line.contains(COMM_PROBABILITY)) {
					stringBuilder.append(line.replace(COMM_PROBABILITY, String.valueOf(commProbability)));
					stringBuilder.append(NEW_LINE);
				} else {
					stringBuilder.append(line);
					stringBuilder.append(NEW_LINE);
				}
			}
			String inputStr = stringBuilder.toString();

			FileOutputStream fileOut = new FileOutputStream(asmPath);
			fileOut.write(inputStr.getBytes());
			fileOut.close();
		} catch (Exception e) {
			error(e);
		}
		return cm;
	}

	/**
	 * 
	 * @param moveCounter
	 * @param outputFile
	 * @param asmPath
	 * @throws IOException
	 */
	public static void editAsmFromLog(int moveCounter, String outputFile, String asmPath) throws IOException {
		StringBuilder sb_predicate = new StringBuilder();
		StringBuilder sb_message = new StringBuilder();
		StringBuilder sb_routing = new StringBuilder();
		Pattern message = Pattern.compile("(Message![0-9]+)");
		Pattern routing = Pattern.compile("(RoutingTable![0-9]+)");

		StringBuilder sbMessageAsm = new StringBuilder();
		StringBuilder sbRoutingAsm = new StringBuilder();

		messageLines = 0;
		routingLines = 0;
		predicateLines = 0;
		uniqueRoutingTables = new ArrayList<>();
		uniqueMessage = new ArrayList<>();
		if (moveCounter > 1) {
			boolean finalState = false;
			try (FileReader in = new FileReader(new File(outputFile)); BufferedReader br = new BufferedReader(in)) {
				String line;
				while ((line = br.readLine()) != null) {
					if (finalState) {
						if (line.startsWith("curSeqNum") || line.startsWith("lastKnownDestSeqNum")
								|| line.startsWith("localReqCount") || line.startsWith("receivedReq")
								|| line.startsWith("waitingForRouteToTmp")) {
							sb_predicate.append(TAB_3 + line.replace("=", ASMETA_EQUAL) + NEW_LINE);
							predicateLines += 1;
						}

						if (line.startsWith("messageType") || line.startsWith("messageRREQ")
								|| line.startsWith("messageRREP") || line.startsWith("messageRERR")
								|| line.startsWith("isConsumed")) {
							try {
								Matcher m = message.matcher(line);
								if (m.find() && !uniqueMessage.contains((String) m.group(1))) {
									uniqueMessage.add(m.group(1));
								}
							} catch (IllegalStateException e) {
								e.printStackTrace();
							}
							messageLines += 1;
							line = line.replace("Message!", ASMETA_VARIABLE + "message");
							sb_message.append(TAB_5 + line.replace("=", ASMETA_EQUAL) + NEW_LINE);
						}

						if (line.startsWith("precursor") || line.startsWith("owner") || line.startsWith("entry(")
								|| line.startsWith("active") || line.startsWith("entryFor")) {
							try {
								Matcher m = routing.matcher(line);
								if (m.find() && !uniqueRoutingTables.contains((String) m.group())) {
									uniqueRoutingTables.add(m.group());
								}
							} catch (IllegalStateException e) {
								error(e);
							}
							routingLines += 1;
							line = line.replace("RoutingTable!", ASMETA_VARIABLE + "rt");
							sb_routing.append(TAB_5 + line.replace("=", ASMETA_EQUAL) + NEW_LINE);
						}
						if (line.startsWith("waitingForRouteTo(")) {
							String value = line.substring(line.indexOf('=') + 1);
							if (value.equals("true")) {
								sb_predicate.append(TAB_3 + line.replace("=", ASMETA_EQUAL) + NEW_LINE);
							}
						}
					}
					if (!finalState && line.toLowerCase().contains("final state:")) {
						finalState = true;
					}
				}
			} catch (Exception e) {
				error(e);
			}

			if (!uniqueMessage.isEmpty()) {
				sbMessageAsm.append(TAB_3 + "extend Message with ");
				for (int i = 0; i < uniqueMessage.size(); i++) {
					sbMessageAsm.append(ASMETA_VARIABLE + "message" + (i + 1));
					if (i < (uniqueMessage.size() - 1)) {
						sbMessageAsm.append(",");
					}
				}
				sbMessageAsm.append(" do" + NEW_LINE);

				if (messageLines > 1)
					sbMessageAsm.append(TAB_4 + ASMETA_PARALLEL_BLOCK_BEGIN + NEW_LINE);

				sbMessageAsm.append(TAB_4 + sb_message.toString());

				if (messageLines > 1)
					sbMessageAsm.append(TAB_4 + ASMETA_PARALLEL_BLOCK_END);
			}

			if (!uniqueRoutingTables.isEmpty()) {
				sbRoutingAsm.append(TAB_3 + "extend RoutingTable with ");
				for (int i = 0; i < uniqueRoutingTables.size(); i++) {
					sbRoutingAsm.append(ASMETA_VARIABLE + "rt" + (i + 1));
					if (i < (uniqueRoutingTables.size() - 1)) {
						sbRoutingAsm.append(",");
					}
				}

				sbRoutingAsm.append(" do" + NEW_LINE);

				if (routingLines > 1)
					sbRoutingAsm.append(TAB_4 + ASMETA_PARALLEL_BLOCK_BEGIN + NEW_LINE);

				sbRoutingAsm.append(TAB_4 + sb_routing.toString());

				if (routingLines > 1)
					sbRoutingAsm.append(TAB_4 + ASMETA_PARALLEL_BLOCK_END);
			}
		}
		try {
			BufferedReader file = new BufferedReader(new FileReader(asmPath));
			String line;
			StringBuffer inputBuffer = new StringBuffer();

			while ((line = file.readLine()) != null) {

				if (line.contains(MESSAGES_CODE)) {
					inputBuffer.append(sbMessageAsm.toString());
				} else if (line.contains(ROUTING_CODE)) {
					inputBuffer.append(sbRoutingAsm.toString());

				} else if (line.contains(PREDICATE_CODE)) {
					inputBuffer.append(sb_predicate.toString());

				} else {
					inputBuffer.append(line);
				}
				inputBuffer.append(NEW_LINE);

				if (line.contains(START_PAR) && canWriteMemoryManager()) {
					inputBuffer.append(TAB_3 + "rule r_MemoryManager =" + NEW_LINE);
					if (canWritePar())
						inputBuffer.append(TAB_3 + "par" + NEW_LINE);
				} else if (line.contains(END_PAR) && canWritePar()) {
					inputBuffer.append(TAB_3 + "endpar" + NEW_LINE);
				} else if (line.contains(START_SEQ_MAIN) && canWriteMemoryManager()) {
					inputBuffer.append(TAB_3 + "seq" + NEW_LINE);
					inputBuffer.append(TAB_4 + "r_MemoryManager[]" + NEW_LINE);
				} else if (line.contains(END_SEQ_MAIN) && canWriteMemoryManager()) {
					inputBuffer.append(TAB_3 + "endseq" + NEW_LINE);
				}
			}
			String inputStr = inputBuffer.toString();

			file.close();
			FileOutputStream fileOut = new FileOutputStream(asmPath);
			fileOut.write(inputStr.getBytes());
			fileOut.close();
		} catch (IOException ex) {
			error(ex);
		}

	}

	/**
	 *
	 * @param outputFile
	 * @return
	 * @throws IOException
	 */
	public static HashMap<String, Integer> parser(String outputFile) throws IOException {

		// Reset metriche istantanee
		metricsMap.put(INST_RREP, 0);
		metricsMap.put(INST_RREQ, 0);
		metricsMap.put(INST_RERR, 0);
		metricsMap.put(RT_UPDATE, 0);
		metricsMap.put(RT_SIZE, 0);

		boolean finalState = false;

		try (FileReader in = new FileReader(outputFile); BufferedReader br = new BufferedReader(in)) {
			String line;
			while ((line = br.readLine()) != null) {
				if (finalState) {
					if (line.contains(RT_UPDATE)) {
						Integer rt_update = Integer.valueOf(line.substring(line.indexOf('=') + 1));
						metricsMap.put(RT_UPDATE, metricsMap.get(RT_UPDATE) + rt_update);
					}

					if (line.startsWith("rreq_update") || line.startsWith("rrep_update")
							|| line.startsWith("rerr_update")) {

						String identifier = line.substring(0, line.indexOf('_'));
						String metric = "";

						switch (identifier) {
						case "rerr":
							metric = INST_RERR;
							break;
						case "rreq":
							metric = INST_RREQ;
							break;
						case "rrep":
							metric = INST_RREP;
							break;
						default:
							break;
						}
						if (!metric.isEmpty()) {
							Integer inst_value = Integer.valueOf(line.substring(line.indexOf('=') + 1));
							metricsMap.put(metric, metricsMap.get(metric) + inst_value);

						}
					}

					if (line.startsWith(CA_SUCCESS) || line.startsWith(CA_FAILURE)) {
						String identifier = line.substring(line.indexOf('_') + 1, line.indexOf('('));
						String metric = "";

						switch (identifier) {
						case "success":
							metric = CA_SUCCESS;
							break;
						case "failure":
							metric = CA_FAILURE;
							break;
						default:
							break;
						}
						if (metric != null) {
							Integer ca_value = Integer.valueOf(line.substring(line.indexOf('=') + 1));
							metricsMap.put(metric, metricsMap.get(metric) + ca_value);
							metricsMap.put(CA_COMPLETED, metricsMap.get(CA_COMPLETED) + ca_value);

						}
					}

					if (line.startsWith(CA_TOT)) {
						Integer ca_value = Integer.valueOf(line.substring(line.indexOf('=') + 1));
						metricsMap.put(CA_TOT, metricsMap.get(CA_TOT) + ca_value);

					}

					if (line.contains("entry(")) {
						metricsMap.put(RT_SIZE, metricsMap.get(RT_SIZE) + 1);

					}
				}

				if (line.toLowerCase().contains("final state")) {
					finalState = true;
				}

			}
		} catch (IOException ex) {
			displayInfo("ERROR: Problem reading file (AODVParser.parser)");
			error(ex);
		}
		return metricsMap;
	}

	// Funzioni di supporto

	/**
	 *
	 * @return
	 */
	public static String getWorkingDir() {
		String working_dir_encoded = Utility.class.getProtectionDomain().getCodeSource().getLocation().getPath();
		try {
			return URLDecoder.decode(working_dir_encoded, "UTF-8");
		} catch (UnsupportedEncodingException e) {
			error(e);
			throw new AssertionError("UTF-8 is unknown"); // https://stackoverflow.com/questions/6030059/url-decoding-unsupportedencodingexception-in-java
		}
	}

	/**
	 *
	 */
	public static void reset() {
		metricsMap.put(CA_TOT, 0);
		metricsMap.put(CA_COMPLETED, 0);
		metricsMap.put(CA_SUCCESS, 0);
		metricsMap.put(CA_FAILURE, 0);
		metricsMap.put(RT_SIZE, 0);
		metricsMap.put(RT_UPDATE, 0);
		metricsMap.put(INST_RREQ, 0);
		metricsMap.put(INST_RREP, 0);
		metricsMap.put(INST_RERR, 0);
	}

	/**
	 * 
	 * @return
	 */
	public static Boolean canWriteMemoryManager() {
		return atleastOneLink || messageLines > 0 || routingLines > 0 || predicateLines > 0;
	}

	/**
	 * 
	 * @return
	 */
	public static Boolean canWritePar() {
		return atleastOneLink || messageLines > 1 || routingLines > 1 || predicateLines > 1;
	}

	/**
	 * 
	 * @param metrics
	 */
	public void revertMetrics(HashMap<String, Integer> metrics) {
		metricsMap = metrics;
	}
}
