argument="$1"
if [[ -z $argument ]] ; then
  echo "No Show argument supplied. Must use showenv show sequence shot"
else
  case $argument in
    bht|man)
      export TF_VAR_SHOW=$argument
      export SHOW=$argument
      ;;
    *)
      raise_error "Unknown argument: ${argument}"
      return
      ;;
  esac
fi

argument2="$2"

if [[ -z $argument2 ]] ; then
  echo "No Sequence argument supplied.  Must use showenv show sequence shot"
else
  case $argument2 in
    tra)
      export TF_VAR_SEQ=$argument2
      export SEQ=$argument2
      ;;
    *)
      raise_error "Unknown argument: ${argument2}"
      return
      ;;
  esac
fi

argument3="$3"

if [[ -z $argument3 ]] ; then
  echo "No Shot argument supplied.  Must use showenv show sequence shot"
else
  case $argument3 in
    0200|0230|0240|0300)
      export TF_VAR_SHOT=$argument3
      export SHOT=$argument3
      ;;
    *)
      raise_error "Unknown argument: ${argument3}"
      return
      ;;
  esac
fi

echo "SHOW: $SHOW"
echo "SEQ: $SEQ"
echo "SHOT: $SHOT"