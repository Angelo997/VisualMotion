package it.uniba.di.application;

import java.io.File;
import java.io.IOException;

/**
 * <p>
 * AsmetaS caller manager
 * </p>
 * 
 */
public class AsmetasExecutor {

	/**
	 * 
	 */
	private AsmetasExecutor() {
	}

	/**
	 * 
	 * @param asmFile
	 * @param simulationDir
	 * @throws IOException
	 * @throws InterruptedException
	 */
	public static void run(String asmFile, String simulationDir) throws IOException, InterruptedException {
		ProcessBuilder pb = new ProcessBuilder("java", "-jar", "asmeta\\AsmetaS.jar", "-n", "1", "-shuffle", asmFile);
		File dirOut = new File(simulationDir + "\\logs\\out.txt");
		File dirErr = new File(simulationDir + "\\logs\\err.txt");
		pb.redirectOutput(dirOut);
		pb.redirectError(dirErr);

		Process p = pb.start();
		int status = p.waitFor();
		// System.out.println("AsmetasExecutor exited with status: " + status);
	}

}
