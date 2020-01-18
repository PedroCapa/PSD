package main.java.restinterface.resources;

import java.net.*;
import java.io.*;
import java.util.ArrayList;
import java.util.List;

import main.java.terminal.ReadMessage;
import main.proto.Protos.Syn;
import main.proto.Protos.Dropwizard;
import main.proto.Protos.ResponseDropProd;
import main.proto.Protos.Production;
import main.proto.Protos.ResponseImporterDropwizard;
import main.proto.Protos.ImporterDropwizard;
import main.proto.Protos.ResponseNegotiationDropwizard;
import main.proto.Protos.NegotiationDropwizard;

public class AskServer{
	public List<Production> askServerProduto(String name) 
	throws IOException, InterruptedException, SocketException{

		Socket cs = new Socket("127.0.0.1", 9999);

		OutputStream out = cs.getOutputStream();
		BufferedReader teclado = new BufferedReader(new InputStreamReader(System.in));
		ReadMessage rm = new ReadMessage(cs);

		//Envia o Syn
		Syn syn = Syn.newBuilder().
						setType(Syn.Type.DROP).
						build();
		
		byte[] send = syn.toByteArray();
		out.write(send);
		
		//Envia o pedido
		Dropwizard drop = Dropwizard.newBuilder().
							setType(Dropwizard.DropType.PROD).
							setUsername(name).
							setProd("PSD").
							build();
		
		byte[] req = drop.toByteArray();
		out.write(req);

		//Recebe o pedido
		byte[] receive = rm.receiveMessage();
		ResponseDropProd rdp = ResponseDropProd.parseFrom(receive);

		System.out.println("Shutdown Output");

		cs.shutdownOutput();
		teclado.close();

		return rdp.getProductsList();

	}

	public List<NegotiationDropwizard> askServerNegocio(String name, String prod) 
	throws IOException, InterruptedException, SocketException{

		Socket cs = new Socket("127.0.0.1", 9999);

		OutputStream out = cs.getOutputStream();
		BufferedReader teclado = new BufferedReader(new InputStreamReader(System.in));
		ReadMessage rm = new ReadMessage(cs);

		//Envia o Syn
		Syn syn = Syn.newBuilder().
						setType(Syn.Type.DROP).
						build();
		
		byte[] send = syn.toByteArray();
		out.write(send);
		
		//Envia o pedido
		Dropwizard drop = Dropwizard.newBuilder().
							setType(Dropwizard.DropType.NEG).
							setUsername(name).
							setProd(prod).
							build();
		
		byte[] req = drop.toByteArray();
		out.write(req);

		//Recebe o pedido
		byte[] receive = rm.receiveMessage();
		ResponseNegotiationDropwizard rdp = ResponseNegotiationDropwizard.parseFrom(receive);

		System.out.println("Shutdown Output");

		cs.shutdownOutput();
		teclado.close();

		return rdp.getNegotiationList();
	}


	public List<ImporterDropwizard> askServerImportador(String name) 
	throws IOException, InterruptedException, SocketException{

		Socket cs = new Socket("127.0.0.1", 9999);

		OutputStream out = cs.getOutputStream();
		BufferedReader teclado = new BufferedReader(new InputStreamReader(System.in));
		ReadMessage rm = new ReadMessage(cs);

		//Envia o Syn
		Syn syn = Syn.newBuilder().
						setType(Syn.Type.DROP).
						build();
		
		byte[] send = syn.toByteArray();
		out.write(send);
		
		//Envia o pedido
		Dropwizard drop = Dropwizard.newBuilder().
							setType(Dropwizard.DropType.IMP).
							setUsername(name).
							setProd("").
							build();
		
		byte[] req = drop.toByteArray();
		out.write(req);

		//Recebe o pedido
		byte[] receive = rm.receiveMessage();
		ResponseImporterDropwizard rdp = ResponseImporterDropwizard.parseFrom(receive);

		System.out.println("Shutdown Output");

		cs.shutdownOutput();
		teclado.close();

		return rdp.getImporterList();
	}
}