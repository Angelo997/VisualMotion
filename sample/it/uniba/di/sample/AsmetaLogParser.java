package it.uniba.di.sample;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

import it.uniba.di.application.Program;

public class AsmetaLogParser extends Utility {

	/**
	 * 
	 * @param filename
	 * @return
	 * @throws IOException
	 */
	public static int extractMoveNumber(String filename) throws IOException {
		int move = 0;

		try (FileReader in = new FileReader(new File(filename)); BufferedReader br = new BufferedReader(in)) {
			String line;
			while ((line = br.readLine()) != null) {
				if (line.contains("</State ")) {
					move = Integer.valueOf(line.substring(8, line.indexOf('(') - 1));
				}
			}
		}

		return move;
	}

	/**
	 * 
	 * @param runId
	 * @param maxRun
	 * @param filename
	 * @throws IOException
	 */
	public static void xmlBuilder(int runId, int maxRun, String filename) throws IOException {
		boolean fileExists = runId > 1;
		boolean endMotionTag = runId == maxRun;
		try (FileWriter fw = new FileWriter(new File("asmeta\\sample\\asmeta.xml"), fileExists);
				FileReader in = new FileReader(new File(filename));
				BufferedReader br = new BufferedReader(in)) {
			String line = br.readLine();
			line = br.readLine();
			if (!fileExists) {
				fw.write("<Motion>");
			}
			fw.write("<Run id=\"" + runId + "\">");
			while ((line = br.readLine()) != null) {
				if (line.contains("<State ")) {
					fw.write("<Move id=\"" + line.substring(7, line.indexOf('(') - 1) + "\">");
				} else if (line.contains("</State ")) {
					fw.write("</Move>");
				} else {
					fw.write("<location>" + line + "</location>");
				}
			}
			fw.write("</Run>");
			if (endMotionTag) {
				fw.write("</Motion>");
			}
		}

		if (endMotionTag) {
			String xmlFormatted = xmlFormatter("asmeta\\sample\\asmeta.xml");
			if (xmlFormatted != null) {
				try (FileWriter fw = new FileWriter(new File("asmeta\\sample\\asmeta.xml"))) {
					fw.write(xmlFormatted);
				}
			}
		}
	}

	/**
	 * 
	 * @param runId
	 * @param filename
	 * @throws IOException
	 *             SISTEMARE!
	 */
	public static void initializerContextPut(int runId, String filename) throws IOException {
		boolean isFirstRun = runId == 1;
		try {
			if (isFirstRun) {
				BufferedReader br = new BufferedReader(new FileReader(filename));
				String line;
				StringBuffer inputBuffer = new StringBuffer();
				while ((line = br.readLine()) != null) {
					if (line.contains("BEGIN_INITIALIZER")) {
						inputBuffer.append(line);
						inputBuffer.append('\n');
						while ((line = br.readLine()) != null && !line.contains("END_INITIALIZER")) {
						}
						String endInitializerLine = line;
						String isInitializedLine = br.readLine();
						// INIZIO CONTESTO (numHost e location associate)
						// TODO

						for (int i = 1; i <= 5; i++) {
							inputBuffer.append("\t\t\t\tcounter(aSM" + i + ") := 0");
							inputBuffer.append('\n');
						}
						
						inputBuffer.append(endInitializerLine + '\n');
						inputBuffer.append(isInitializedLine);
						inputBuffer.append('\n');
						// FINE CONTESTO
					} else {
						inputBuffer.append(line);
						inputBuffer.append('\n');
					}
				}
				String inputStr = inputBuffer.toString();
				br.close();
				FileOutputStream fileOut = new FileOutputStream(filename);
				fileOut.write(inputStr.getBytes());
				fileOut.close();
			}
		} catch (Exception e) {
			Program.progressList.add("ERROR: Problem reading file.");
			Program.progressList.select(Program.progressList.getItemCount() - 1);
		}
	}
}
